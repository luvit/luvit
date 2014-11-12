--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

-- Derived from Yichun Zhang (agentzh)
-- https://github.com/openresty/lua-resty-dns/blob/master/lib/resty/dns/resolver.lua

local dgram = require('dgram')
local timer = require('timer')
local Error = require('core').Error
local bit = require('bit')

local crypto = require('lcrypto')
local char = string.char
local byte = string.byte
local find = string.find
local gsub = string.gsub
local sub = string.sub
local format = string.format
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift
local insert = table.insert
local concat = table.concat
local setmetatable = setmetatable
local type = type

local SERVERS = {
  {
    ['host'] = '8.8.8.8',
    ['port'] = 53
  },
}

local DEFAULT_TIMEOUT = 5000   -- 5 seconds

local TYPE_A      = 1
local TYPE_NS     = 2
local TYPE_CNAME  = 5
local TYPE_PTR    = 12
local TYPE_MX     = 15
local TYPE_TXT    = 16
local TYPE_AAAA   = 28
local TYPE_SRV    = 33

local CLASS_IN    = 1

local resolver_errstrs = {
  "format error",     -- 1
  "server failure",   -- 2
  "name error",       -- 3
  "not implemented",  -- 4
  "refused",          -- 5
}

--[[

]]--
local function _gen_id(self)
  local bytes = crypto.randomBytes(2)
  return bor(lshift(bytes:byte(1), 8), band(bytes:byte(2), 0xff))
end

--[[

]]--
local function _encode_name(s)
  return char(#s) .. s
end

--[[

]]--
local function _decode_name(buf, pos)
  local labels = {}
  local nptrs = 0
  local p = pos
  while nptrs < 128 do
    local fst = byte(buf, p)

    if not fst then
      return nil, 'truncated';
    end

    -- print("fst at ", p, ": ", fst)

    if fst == 0 then
      if nptrs == 0 then
        pos = pos + 1
      end
      break
    end

    if band(fst, 0xc0) ~= 0 then
      -- being a pointer
      if nptrs == 0 then
        pos = pos + 2
      end

      nptrs = nptrs + 1

      local snd = byte(buf, p + 1)
      if not snd then
        return nil, 'truncated'
      end

      p = lshift(band(fst, 0x3f), 8) + snd + 1

      -- print("resolving ptr ", p, ": ", byte(buf, p))

    else
      -- being a label
      local label = sub(buf, p + 1, p + fst)
      insert(labels, label)

      -- print("resolved label ", label)

      p = p + fst + 1

      if nptrs == 0 then
        pos = p
      end
    end
  end

  return concat(labels, "."), pos
end

local function _build_request(qname, id, no_recurse, opts)
  local qtype

  if opts then
    qtype = opts.qtype
  end

  if not qtype then
    qtype = 1  -- A record
  end

  local ident_hi = char(rshift(id, 8))
  local ident_lo = char(band(id, 0xff))

  local flags
  if no_recurse then
    -- print("found no recurse")
    flags = "\0\0"
  else
    flags = "\1\0"
  end

  local nqs = "\0\1"
  local nan = "\0\0"
  local nns = "\0\0"
  local nar = "\0\0"
  local typ = "\0" .. char(qtype)
  local class = "\0\1"    -- the Internet class

  if byte(qname, 1) == DOT_CHAR then
    return nil, "bad name"
  end

  local name = gsub(qname, "([^.]+)%.?", _encode_name) .. '\0'

  return table.concat({
    ident_hi, ident_lo, flags, nqs, nan, nns, nar,
    name, typ, class
  })
end

local function parse_response(buf, id)
  local n = #buf
  if n < 12 then
    return nil, 'truncated';
  end

  -- header layout: ident flags nqs nan nns nar

  local ident_hi = byte(buf, 1)
  local ident_lo = byte(buf, 2)
  local ans_id = lshift(ident_hi, 8) + ident_lo

  -- print("id: ", id, ", ans id: ", ans_id)

  if ans_id ~= id then
    -- identifier mismatch and throw it away
    log(DEBUG, "id mismatch in the DNS reply: ", ans_id, " ~= ", id)
    return nil, "id mismatch"
  end

  local flags_hi = byte(buf, 3)
  local flags_lo = byte(buf, 4)
  local flags = lshift(flags_hi, 8) + flags_lo

  -- print(format("flags: 0x%x", flags))

  if band(flags, 0x8000) == 0 then
    return nil, format("bad QR flag in the DNS response")
  end

  if band(flags, 0x200) ~= 0 then
    return nil, "truncated"
  end

  local code = band(flags, 0x7f)

  -- print(format("code: %d", code))

  local nqs_hi = byte(buf, 5)
  local nqs_lo = byte(buf, 6)
  local nqs = lshift(nqs_hi, 8) + nqs_lo

  -- print("nqs: ", nqs)

  if nqs ~= 1 then
    return nil, format("bad number of questions in DNS response: %d", nqs)
  end

  local nan_hi = byte(buf, 7)
  local nan_lo = byte(buf, 8)
  local nan = lshift(nan_hi, 8) + nan_lo

  -- print("nan: ", nan)

  -- skip the question part

  local ans_qname, pos = _decode_name(buf, 13)
  if not ans_qname then
    return nil, pos
  end

  -- print("qname in reply: ", ans_qname)

  -- print("question: ", sub(buf, 13, pos))

  if pos + 3 + nan * 12 > n then
    -- print(format("%d > %d", pos + 3 + nan * 12, n))
    return nil, 'truncated';
  end

  -- question section layout: qname qtype(2) qclass(2)

  local type_hi = byte(buf, pos)
  local type_lo = byte(buf, pos + 1)
  local ans_type = lshift(type_hi, 8) + type_lo

  -- print("ans qtype: ", ans_type)

  local class_hi = byte(buf, pos + 2)
  local class_lo = byte(buf, pos + 3)
  local qclass = lshift(class_hi, 8) + class_lo

  -- print("ans qclass: ", qclass)

  if qclass ~= 1 then
    return nil, format("unknown query class %d in DNS response", qclass)
  end

  pos = pos + 4

  local answers = {}

  if code ~= 0 then
    answers.errcode = code
    answers.errstr = resolver_errstrs[code] or "unknown"
  end

  for i = 1, nan do
    -- print(format("ans %d: qtype:%d qclass:%d", i, qtype, qclass))

    local ans = {}
    insert(answers, ans)

    local name
    name, pos = _decode_name(buf, pos)
    if not name then
      return nil, pos
    end

    ans.name = name

    -- print("name: ", name)

    type_hi = byte(buf, pos)
    type_lo = byte(buf, pos + 1)
    local typ = lshift(type_hi, 8) + type_lo

    ans.type = typ

    -- print("type: ", typ)

    class_hi = byte(buf, pos + 2)
    class_lo = byte(buf, pos + 3)
    local class = lshift(class_hi, 8) + class_lo

    ans.class = class

    -- print("class: ", class)

    local ttl_bytes = { byte(buf, pos + 4, pos + 7) }

    -- print("ttl bytes: ", concat(ttl_bytes, " "))

    local ttl = lshift(ttl_bytes[1], 24) + lshift(ttl_bytes[2], 16)
    + lshift(ttl_bytes[3], 8) + ttl_bytes[4]

    -- print("ttl: ", ttl)

    ans.ttl = ttl

    local len_hi = byte(buf, pos + 8)
    local len_lo = byte(buf, pos + 9)
    local len = lshift(len_hi, 8) + len_lo

    -- print("record len: ", len)

    pos = pos + 10

    if typ == TYPE_A then

      if len ~= 4 then
        return nil, "bad A record value length: " .. len
      end

      local addr_bytes = { byte(buf, pos, pos + 3) }
      local addr = concat(addr_bytes, ".")
      -- print("ipv4 address: ", addr)

      ans.address = addr

      pos = pos + 4

    elseif typ == TYPE_CNAME then

      local cname, p = _decode_name(buf, pos)
      if not cname then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad cname record length: %d ~= %d",
        p - pos, len)
      end

      pos = p

      -- print("cname: ", cname)

      ans.cname = cname

    elseif typ == TYPE_AAAA then

      if len ~= 16 then
        return nil, "bad AAAA record value length: " .. len
      end

      local addr_bytes = { byte(buf, pos, pos + 15) }
      local flds = {}
      local comp_begin, comp_end
      for i = 1, 16, 2 do
        local a = addr_bytes[i]
        local b = addr_bytes[i + 1]
        if a == 0 then
          insert(flds, format("%x", b))

        else
          insert(flds, format("%x%02x", a, b))
        end
      end

      -- we do not compress the IPv6 addresses by default
      --  due to performance considerations

      ans.address = concat(flds, ":")

      pos = pos + 16

    elseif typ == TYPE_MX then

      -- print("len = ", len)

      if len < 3 then
        return nil, "bad MX record value length: " .. len
      end

      local pref_hi = byte(buf, pos)
      local pref_lo = byte(buf, pos + 1)

      ans.preference = lshift(pref_hi, 8) + pref_lo

      local host, p = _decode_name(buf, pos + 2)
      if not host then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad cname record length: %d ~= %d",
        p - pos, len)
      end

      ans.exchange = host

      pos = p

    elseif typ == TYPE_SRV then
      if len < 7 then
        return nil, "bad SRV record value length: " .. len
      end

      local prio_hi = byte(buf, pos)
      local prio_lo = byte(buf, pos + 1)
      ans.priority = lshift(prio_hi, 8) + prio_lo

      local weight_hi = byte(buf, pos + 2)
      local weight_lo = byte(buf, pos + 3)
      ans.weight = lshift(weight_hi, 8) + weight_lo

      local port_hi = byte(buf, pos + 4)
      local port_lo = byte(buf, pos + 5)
      ans.port = lshift(port_hi, 8) + port_lo

      local name, p = _decode_name(buf, pos + 6)
      if not name then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad srv record length: %d ~= %d",
        p - pos, len)
      end

      ans.target = name

      pos = p

    elseif typ == TYPE_NS then

      local name, p = _decode_name(buf, pos)
      if not name then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad cname record length: %d ~= %d",
        p - pos, len)
      end

      pos = p

      -- print("name: ", name)

      ans.nsdname = name

    elseif typ == TYPE_TXT then

      local slen = byte(buf, pos)
      if slen + 1 > len then
        -- truncate the over-run TXT record data
        slen = len
      end

      -- print("slen: ", len)

      local val = sub(buf, pos + 1, pos + slen)
      local last = pos + len
      pos = pos + slen + 1

      if pos < last then
        -- more strings to be processed
        -- this code path is usually cold, so we do not
        -- merge the following loop on this code path
        -- with the processing logic above.

        val = {val}
        local idx = 2
        repeat
          local slen = byte(buf, pos)
          if pos + slen + 1 > last then
            -- truncate the over-run TXT record data
            slen = last - pos - 1
          end

          val[idx] = sub(buf, pos + 1, pos + slen)
          idx = idx + 1
          pos = pos + slen + 1

        until pos >= last
      end

      ans.txt = val

    elseif typ == TYPE_PTR then

      local name, p = _decode_name(buf, pos)
      if not name then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad cname record length: %d ~= %d",
        p - pos, len)
      end

      pos = p

      -- print("name: ", name)

      ans.ptrdname = name

    else
      -- for unknown types, just forward the raw value

      ans.rdata = sub(buf, pos, pos + len - 1)
      pos = pos + len
    end
  end

  return answers
end

local function _query(name, dnsclass, qtype, callback)
  local tries = 1
  local max_tries = 5

  local function get_server_iter()
    local i = 1
    return function()
      i = ((i + 1) % #SERVERS) + 1
      return SERVERS[i]
    end
  end

  local server = get_server_iter()

  local udp_iter
  udp_iter = function()
    tries = tries + 1
    if tries > max_tries then
      return callback(Error:new('Maximum attempts reached'))
    end

    local srv = server()
    local id = _gen_id()
    local req = _build_request(name, id, false, { qtype = qtype })
    local sock = dgram.createSocket()
    sock:send(req, srv.host, srv.port)
    sock:on('message', function(msg)
      sock:close()
      answers, err = parse_response(msg, id)
      if answers then
        callback(nil, answers)
      else
        timer.setImmediate(udp_iter)
      end
    end)
  end

  udp_iter()
end

exports.resolve4 = function(name, callback)
  _query(name, CLASS_IN, TYPE_A, callback)
end

exports.resolve6 = function(name, callback)
  _query(name, CLASS_IN, TYPE_AAAA, callback)
end

exports.resolveSrv = function(name, callback)
  _query(name, CLASS_IN, TYPE_SRV, callback)
end

exports.resolveMx = function(name, callback)
  _query(name, CLASS_IN, TYPE_MX, callback)
end

exports.resolveNs = function(name, callback)
  _query(name, CLASS_IN, TYPE_NS, callback)
end

exports.resolveCname = function(name, callback)
  _query(name, CLASS_IN, TYPE_CNAME, callback)
end

exports.resolveTxt = function(name, callback)
  _query(name, CLASS_IN, TYPE_TXT, callback)
end

exports.setServers = function(servers)
  SERVERS = servers
end
