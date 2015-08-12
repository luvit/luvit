--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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

exports.name = "luvit/dns"
exports.version = "1.0.0-10"
exports.dependencies = {
  "luvit/dgram@1.1.0",
  "luvit/fs@1.2.2",
  "luvit/net@1.2.0",
  "luvit/timer@1.0.0",
  "luvit/core@1.0.5",
  "luvit/tls@1.3.0",
  "luvit/utils@1.0.0",
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/dns.lua"
exports.description = "Node-style dns module for luvit"
exports.tags = {"luvit", "dns"}

local dgram = require('dgram')
local fs = require('fs')
local net = require('net')
local timer = require('timer')
local Error = require('core').Error
local adapt = require('utils').adapt

local bit = require('bit')
local crypto = require('tls/lcrypto')
local char = string.char
local byte = string.byte
local gsub = string.gsub
local sub = string.sub
local format = string.format
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift
local insert = table.insert
local concat = table.concat

local DEFAULT_SERVERS = {
  {
    ['host'] = '8.8.8.8',
    ['port'] = 53,
    ['tcp'] = false
  },
  {
    ['host'] = '8.8.4.4',
    ['port'] = 53,
    ['tcp'] = false
  },
}
local SERVERS = DEFAULT_SERVERS
local DEFAULT_TIMEOUT = 2000   -- 2 seconds
local TIMEOUT = DEFAULT_TIMEOUT

exports.TYPE_A      = 1
exports.TYPE_NS     = 2
exports.TYPE_CNAME  = 5
exports.TYPE_PTR    = 12
exports.TYPE_MX     = 15
exports.TYPE_TXT    = 16
exports.TYPE_AAAA   = 28
exports.TYPE_SRV    = 33

exports.CLASS_IN    = 1

local resolver_errstrs = {
  "format error",     -- 1
  "server failure",   -- 2
  "name error",       -- 3
  "not implemented",  -- 4
  "refused",          -- 5
}

local DOT_CHAR = 46

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

  return {
    ident_hi, ident_lo, flags, nqs, nan, nns, nar,
    name, typ, class
  }
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

  local type_hi, type_lo

  -- local type_hi = byte(buf, pos)
  -- local type_lo = byte(buf, pos + 1)
  -- local ans_type = lshift(type_hi, 8) + type_lo
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

    if typ == exports.TYPE_A then

      if len ~= 4 then
        return nil, "bad A record value length: " .. len
      end

      local addr_bytes = { byte(buf, pos, pos + 3) }
      local addr = concat(addr_bytes, ".")
      -- print("ipv4 address: ", addr)

      ans.address = addr

      pos = pos + 4

    elseif typ == exports.TYPE_CNAME then

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

    elseif typ == exports.TYPE_AAAA then

      if len ~= 16 then
        return nil, "bad AAAA record value length: " .. len
      end

      local addr_bytes = { byte(buf, pos, pos + 15) }
      local flds = {}
      for idx = 1, 16, 2 do
        local a = addr_bytes[idx]
        local b = addr_bytes[idx + 1]
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

    elseif typ == exports.TYPE_MX then

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

    elseif typ == exports.TYPE_SRV then
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

      local recname, p = _decode_name(buf, pos + 6)
      if not recname then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad srv record length: %d ~= %d", p - pos, len)
      end

      ans.target = recname

      pos = p

    elseif typ == exports.TYPE_NS then

      local recname, p = _decode_name(buf, pos)
      if not recname then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad cname record length: %d ~= %d",
        p - pos, len)
      end

      pos = p

      -- print("name: ", recname)

      ans.nsdname = recname

    elseif typ == exports.TYPE_TXT then

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
          local recslen = byte(buf, pos)
          if pos + recslen + 1 > last then
            -- truncate the over-run TXT record data
            recslen = last - pos - 1
          end

          val[idx] = sub(buf, pos + 1, pos + recslen)
          idx = idx + 1
          pos = pos + recslen + 1

        until pos >= last
      end

      ans.txt = val

    elseif typ == exports.TYPE_PTR then

      local recname, p = _decode_name(buf, pos)
      if not recname then
        return nil, pos
      end

      if p - pos ~= len then
        return nil, format("bad cname record length: %d ~= %d",
        p - pos, len)
      end

      pos = p

      -- print("name: ", recname)

      ans.ptrdname = recname

    else
      -- for unknown types, just forward the raw value

      ans.rdata = sub(buf, pos, pos + len - 1)
      pos = pos + len
    end
  end

  return answers
end

local function _query(servers, name, dnsclass, qtype, callback)
  local tries, max_tries, server, tcp_iter, udp_iter, get_server_iter

  tries = 1
  max_tries = 5

  get_server_iter = function()
    local i = 1
    return function()
      i = (i % #servers) + 1
      return servers[i]
    end
  end

  server = get_server_iter()

  tcp_iter = function()
    local srv, id, req, len, len_hi, len_lo, sock
    local onTimeout, onConnect, onData, onError

    tries = tries + 1
    if tries > max_tries then
      return callback(Error:new('Maximum attempts reached'))
    end

    srv = server()
    id = _gen_id()
    req = _build_request(name, id, false, { qtype = qtype })
    req = table.concat(req, "")
    len = #req
    len_hi = char(rshift(len, 8))
    len_lo = char(band(len, 0xff))
    sock = net.Socket:new()

    function onError(err)
      sock:destroy()
      timer.setImmediate(tcp_iter)
    end

    function onTimeout()
      sock:destroy()
      timer.setImmediate(tcp_iter)
    end

    function onConnect(err)
      if err then
        sock:destroy()
        return timer.setImmediate(tcp_iter)
      end
      sock:on('data', onData)
      sock:on('error', onError)
      sock:write(table.concat({len_hi, len_lo, req}))
    end

    function onData(msg)
      local len_hi, len_lo, len, answers

      len_hi = byte(msg, 1)
      len_lo = byte(msg, 2)
      len = lshift(len_hi, 8) + len_lo

      assert(#msg - 2 == len)

      sock:destroy()

      answers = parse_response(msg:sub(3), id)
      if not answers then
        timer.setImmediate(tcp_iter)
      else
        callback(nil, answers)
      end
    end

    sock:setTimeout(TIMEOUT, onTimeout)
    sock:connect(srv.port, srv.host, onConnect)
  end

  udp_iter = function()
    local srv, id, req, sock, onTimeout, onMessage, onError

    tries = tries + 1
    if tries > max_tries then
      return callback(Error:new('Maximum attempts reached'))
    end

    srv = server()
    id = _gen_id()
    req = _build_request(name, id, false, { qtype = qtype })
    sock = dgram.createSocket()

    function onError(err)
      sock:close()
      timer.setImmediate(udp_iter)
    end

    function onTimeout()
      sock:close()
      timer.setImmediate(udp_iter)
    end

    function onMessage(msg)
      sock:close()
      local answers, err = parse_response(msg, id)
      if answers then
        callback(nil, answers)
      else
        if err == 'truncated' then
          timer.setImmediate(tcp_iter)
        else
          timer.setImmediate(udp_iter)
        end
      end
    end

    sock:send(table.concat(req), srv.port, srv.host)
    sock:recvStart()
    sock:setTimeout(TIMEOUT, onTimeout)
    sock:on('message', onMessage)
    sock:on('error', onError)
  end

  if server().tcp then
    tcp_iter()
  else
    udp_iter()
  end
end

local function query(servers, name, dnsclass, qtype, callback)
  return adapt(callback, _query, servers, name, dnsclass, qtype)
end
exports.query = query

exports.resolve4 = function(name, callback)
  return query(SERVERS, name, exports.CLASS_IN, exports.TYPE_A, callback)
end

exports.resolve6 = function(name, callback)
  return query(SERVERS, name, exports.CLASS_IN, exports.TYPE_AAAA, callback)
end

exports.resolveSrv = function(name, callback)
  return query(SERVERS, name, exports.CLASS_IN, exports.TYPE_SRV, callback)
end

exports.resolveMx = function(name, callback)
  return query(SERVERS, name, exports.CLASS_IN, exports.TYPE_MX, callback)
end

exports.resolveNs = function(name, callback)
  return query(SERVERS, name, exports.CLASS_IN, exports.TYPE_NS, callback)
end

exports.resolveCname = function(name, callback)
  return query(SERVERS, name, exports.CLASS_IN, exports.TYPE_CNAME, callback)
end

exports.resolveTxt = function(name, callback)
  return query(SERVERS, name, exports.CLASS_IN, exports.TYPE_TXT, callback)
end

exports.setServers = function(servers)
  SERVERS = servers
end

exports.setTimeout = function(timeout)
  TIMEOUT = timeout
end

exports.setDefaultTimeout = function()
  TIMEOUT = DEFAULT_TIMEOUT
end

exports.setDefaultServers = function()
  SERVERS = DEFAULT_SERVERS
end

exports.loadResolver = function(options)
  local servers = {}

  options = options or {
    file = '/etc/resolv.conf'
  }

  local data, err = fs.readFileSync(options.file)
  if err then return end

  local posa = 1

  local function parse(line)
    if not line:match('^#') then
      local ip = line:match('nameserver%s(.*)')
      if ip then
        local server = {}
        server.host = ip
        server.port = 53
        table.insert(servers, server)
      end
    end
  end

  while 1 do
    local pos, chars = data:match('()([\r\n].?)', posa)
    if pos then
      if chars == '\r\n' then pos = pos + 1 end
      local line = data:sub(posa, pos - 1)
      parse(line)
      posa = pos + 1
    else
      local line = data:sub(posa)
      parse(line)
      break
    end
  end

  SERVERS = servers

  return servers
end
