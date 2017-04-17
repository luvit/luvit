-----------------------------------------------------------------------------
-- SMTP client support for the Lua language.
-- LuaSocket toolkit.
-- Author: Diego Nehab
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------
local base = _G
local coroutine = require("coroutine")
local string = require("string")
local math = require("math")
local os = require("os")
local ltn12 = require("./ltn12")
local headers = require("./headers")
local mime = require("./mime")

local net = require'net'
local Emitter = require('core').Emitter

local _M = Emitter:extend()

-----------------------------------------------------------------------------
-- Program constants
-----------------------------------------------------------------------------
-- timeout for connection
_M.TIMEOUT = 60
-- default server used to send e-mails
_M.SERVER = "localhost"
-- default port
_M.PORT = 25
-- domain used in HELO command and default sendmail
-- If we are under a CGI, try to get from environment
_M.DOMAIN = os.getenv("SERVER_NAME") or "localhost"
-- default time zone (means we don't know)
_M.ZONE = "-0000"

-----------------------------------------------------------------------------
-- Low level SMTP API
-----------------------------------------------------------------------------
local function command(cmd, arg)
    cmd = string.upper(cmd)
    if arg then
        return cmd .. " " .. arg.. "\r\n"
    else
        return cmd .. "\r\n"
    end
end


function _M:initialize()
end

function _M:command(cmd, expect, callback)
    self.socket:write(cmd,function(e)
        if e then
            return _M:emit('error','IO Error:'..e)
        end
        self.socket:once('data',function(s)
            --p('Q:',cmd)
            --p('R:',s)
            if string.find(s,expect) then
                callback(s)
            else
                _M:emit('error',string.format('expect %s but %s',expect,s))
            end
        end)
    end)
end

function _M:auth(user,password,ext,callback)
    assert(user)
    assert(password)
    assert(ext)
    if string.find(ext, "AUTH[^\n]+LOGIN") then
        self:command(command("AUTH", "LOGIN"), '3..', function(msg)
            self:command(mime.b64(user)..'\r\n','3..',function(msg)
                self:command(mime.b64(password)..'\r\n','2..',function(msg)
                    callback(msg)
                end)
            end)
        end)
    elseif string.find(ext, "AUTH[^\n]+PLAIN") then
        local auth = "PLAIN " .. mime.b64("\0" .. user .. "\0" .. password)
        self:command(command("AUTH", auth),'2..', function(msg)
            callback(msg)
        end)
    else
        assert(nil, "authentication not supported")
    end
end

function _M:senddata(mailt,callback)
    if type(mailt.message)=='table' then
      mailt.source = mailt.source or smtp.message(mailt.message)
    end
    local src, step = ltn12.source.chain(mailt.source, mime.stuff()), mailt.step
    local t = {}
    local sink = ltn12.sink.table(t)
    local ret, err = ltn12.pump.all(src, sink, step or ltn12.pump.step)
    t = table.concat(t)
    assert(ret,err)
    self:command(command("DATA"),'3..',function(msg)
        self.socket:write(t,function(e)
            assert(not e, e)
            self:command('\r\n.\r\n','2..',function(msg)
                self:quit(callback)
            end)
        end)
    end)
end

function _M:quit(callback)
    self:command(command("QUIT"),'2..', function(msg)
        self:emit('done')
        if callback then callback(nil, msg) end
    end)
end

function _M:send(mailt, callback)
    self:command(command("EHLO", assert(mailt.domain or self.socket.domain)),'2..',function(msg)
        self:auth(mailt.user, mailt.password, msg, function(msg)
           self:command(command("MAIL", "FROM:" .. mailt.from),'2..', function(msg)
                local rcpt = mailt.rcpt
                if type(rcpt)=='string' then
                    self:command(command("RCPT", "TO:" .. rcpt),'2..', function(msg)
                        self:senddata(mailt,callback)
                    end)
                else
                    local i=1
                    local rcpto
                    rcpto = function()
                        if i<=#rcpt then
                            self:command(command("RCPT", "TO:" .. rcpt[i]),'2..', function(msg)
                                i = i+1
                                rcpto()
                            end)
                        else
                            self:senddata(mailt,callback)
                        end
                    end
                    rcpto()
                end
            end)
        end)
    end)
end

function _M:open(port,server, callback)
    assert(not self.socket, 'alreay opend')
    assert(callback)
    self.socket = net.Socket:new()
    self.socket:on('error',function(e)
        self:emit('error',e,'IO')
    end)

    self.socket:connect(port,server,function()
        self.socket:once('data',function(s)
            if string.find(s,'2..') then
                self.socket.domain = server
                callback()
            else
                self:emit('error', 'greeting fail:'..s, 'SMTP')
            end
        end)
    end)
end

function _M:close(callback)
    if self.socket then
        self.socket:close(function()
            self.socket = nil
            if(callback) then
                callback()
            end
        end)
    end
end

-- convert headers to lowercase
local function lower_headers(headers)
    local lower = {}
    for i,v in base.pairs(headers or lower) do
        lower[string.lower(i)] = v
    end
    return lower
end

---------------------------------------------------------------------------
-- Multipart message source
-----------------------------------------------------------------------------
-- returns a hopefully unique mime boundary

local seqno = 0
local function newboundary()
    seqno = seqno + 1
    return string.format('%s%05d==%05u', os.date('%d%m%Y%H%M%S'),
        math.random(0, 99999), seqno)
end

-- send_message forward declaration
local send_message

-- yield the headers all at once, it's faster
local function send_headers(tosend)
    local canonic = headers.canonic
    local h = "\r\n"
    for f,v in base.pairs(tosend) do
        h = (canonic[f] or f) .. ': ' .. v .. "\r\n" .. h
    end
    coroutine.yield(h)
end

-- yield multipart message body from a multipart message table
local function send_multipart(mesgt)
    -- make sure we have our boundary and send headers
    local bd = newboundary()
    local headers = lower_headers(mesgt.headers or {})
    headers['content-type'] = headers['content-type'] or 'multipart/mixed'
    headers['content-type'] = headers['content-type'] ..
        '; boundary="' ..  bd .. '"'
    send_headers(headers)
    -- send preamble
    if mesgt.body.preamble then
        coroutine.yield(mesgt.body.preamble)
        coroutine.yield("\r\n")
    end
    -- send each part separated by a boundary
    for i, m in base.ipairs(mesgt.body) do
        coroutine.yield("\r\n--" .. bd .. "\r\n")
        send_message(m)
    end
    -- send last boundary
    coroutine.yield("\r\n--" .. bd .. "--\r\n\r\n")
    -- send epilogue
    if mesgt.body.epilogue then
        coroutine.yield(mesgt.body.epilogue)
        coroutine.yield("\r\n")
    end
end

-- yield message body from a source
local function send_source(mesgt)
    -- make sure we have a content-type
    local headers = lower_headers(mesgt.headers or {})
    headers['content-type'] = headers['content-type'] or
        'text/plain; charset="iso-8859-1"'
    send_headers(headers)
    -- send body from source
    while true do
        local chunk, err = mesgt.body()
        if err then coroutine.yield(nil, err)
        elseif chunk then coroutine.yield(chunk)
        else break end
    end
end

-- yield message body from a string
local function send_string(mesgt)
    -- make sure we have a content-type
    local headers = lower_headers(mesgt.headers or {})
    headers['content-type'] = headers['content-type'] or
        'text/plain; charset="iso-8859-1"'
    send_headers(headers)
    -- send body from string
    coroutine.yield(mesgt.body)
end

-- message source
function send_message(mesgt)
    if base.type(mesgt.body) == "table" then send_multipart(mesgt)
    elseif base.type(mesgt.body) == "function" then send_source(mesgt)
    else send_string(mesgt) end
end

-- set defaul headers
local function adjust_headers(mesgt)
    local lower = lower_headers(mesgt.headers)
    lower["date"] = lower["date"] or
        os.date("!%a, %d %b %Y %H:%M:%S ") .. (mesgt.zone or _M.ZONE)
    lower["x-mailer"] = lower["x-mailer"] or "luvit mail v1"
    -- this can't be overriden
    lower["mime-version"] = "1.0"
    return lower
end

function _M.message(mesgt)
    mesgt.headers = adjust_headers(mesgt)
    -- create and return message source
    local co = coroutine.create(function() send_message(mesgt) end)
    return function()
        local ret, a, b = coroutine.resume(co)
        if ret then return a, b
        else return nil, a end
    end
end

return _M
