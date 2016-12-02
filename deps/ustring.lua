local ustring = {}
local tostring = tostring
local _meta = {}

local strsub = string.sub
local strbyte = string.byte
local band = bit.band
local rshift = bit.rshift
function ustring.new(str,allowInvaild)
    local str = str and tostring(str) or ""
    local ustr = {}
    local index = 1;
    local append = 0;
    for i = 1,#str do
        repeat
        local char = strsub(str,i,i)
        local byte = strbyte(char)
        if append ~= 0 then
            if not allowInvaild then
                if rshift(byte,6) ~= 0x02 then
                    error("Invaild UTF-8 sequence at "..i)
                end
            end
            ustr[index] = ustr[index] .. char
            append = append - 1
            if append == 0 then
                index = index + 1
            end
            break
        end

        if rshift(byte,7) == 0x00 then -- 1 byte (ansi)
            ustr[index] = char
            index = index + 1
        elseif rshift(byte,5) == 0x06 then -- 2 bytes
            ustr[index] = char
            append = 1
        elseif rshift(byte,4) == 0x0E then -- 3 bytes
            ustr[index] = char
            append = 2
        elseif rshift(byte,3) == 0x1E then -- 4 bytes
            ustr[index] = char
            append = 3
        else
            -- RFC 3629 (2003.11) says UTF-8 don't have characters larger than 4 bytes.
            -- They will not be processed although they may be appeared in some old systems.
            if not allowInvaild then
                error("Invaild UTF-8 sequence at "..i..",byte:"..byte)
            end
        end

        until true
    end
    setmetatable(ustr,_meta)
    return ustr
end

function ustring.copy(ustr)
    local u = ustring.new()
    for i = 1,#ustr do
        u[i] = ustr[i]
    end
    return u
end

function ustring.uindex(ustr,rawindex,initrawindex,initindex)
    -- get the index of the UTF-8 character from a raw string index
    -- return `nil` when rawindex is invaild
    -- the last 2 arguments is used for speed up
    local index = (initindex or 1)
    rawindex = rawindex - (initrawindex or 1) + 1
    repeat
        local byte = ustr[index]
        if byte == nil then return nil end
        local len = #byte
        index = index + 1
        rawindex = rawindex - len
    until rawindex <= 0
    return index - 1
end

local gsub = string.gsub
local find = string.find
local format = string.format
local gmatch = string.gmatch
local match = string.match
local lower = string.lower
local upper = string.upper
ustring.len = rawlen

function ustring.gsub(ustr,pattern,repl,n)
    return ustring.new(gsub(tostring(ustr),tostring(pattern),tostring(repl),n))
end

function ustring.sub(ustr,i,j)
    local u = ustring.new()
    j = j or -1
    local len = #ustr
    if i < 0 then i = len + i + 1 end
    if j < 0 then j = len + j + 1 end
    for ii = i,math.min(j,len) do
        u[#u + 1] = ustr[ii]
    end
    return u
end

function ustring.find(ustr,pattern,init,plain)
    local first,last = find(tostring(ustr),tostring(pattern),init,plain)
    local ufirst = ustring.uindex(ustr,first)
    local ulast = ustring.uindex(ustr,last,first,ufirst)
    return ufirst,ulast
end

function ustring.format(formatstring,...)
    return ustring.new(format(tostring(formatstring),...))
end

function ustring.gmatch(ustr,pattern)
    return gmatch(tostring(ustr),pattern)
end

function ustring.match(ustr,pattern,init)
    return match(tostring(ustr),tostring(pattern),init)
end

function ustring.lower(ustr)
    local u = ustring.copy(ustr)
    for i = 1,#u do
        u = lower(u)
    end
    return u
end

function ustring.upper(ustr)
    local u = ustring.copy(ustr)
    for i = 1,#u do
        u = upper(u)
    end
    return u
end

function ustring.rep(ustr,n)
    local u = ustring.new()
    for i = 1,n do
        for ii = 1,#ustr do
           u[#u + 1] = ustr[ii]
        end
    end
    return u
end

function ustring.reverse(ustr)
    local u = ustring.copy(ustr)
    local len = #ustr;
    for i = 1,len do
        u[i] = ustr[len - i + 1]
    end
    return u
end

_meta.__index = ustring

function _meta.__eq(ustr1,ustr2)
    if type(ustr2) == "string" then
        return tostring(ustr1) == ustr2
    end
    local len1 = #ustr1
    local len2 = #ustr2
    if len1 ~= len2 then return false end

    for i = 1,len1 do
        if ustr1[i] ~= ustr2[i] then return false end
    end
    return true
end

function _meta.__tostring(self)
    return tostring(table.concat(self))
end

function _meta.__concat(ustr1,ustr2)
    local u = ustring.copy(ustr1)
    for i = 1,#ustr2 do
        u[#u + 1] = ustr2[i]
    end
    return u
end

_meta.__len = ustring.len

return ustring
