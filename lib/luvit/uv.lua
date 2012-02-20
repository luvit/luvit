local native = require('uv_native')
local Object = require('core').Object
local Emitter = require('core').Emitter
local iStream = require('core').iStream

local uv = Object:extend()

--------------------------------------------------------------------------------

--[[
This class is never used directly, but is the inheritance chain of all libuv
objects.
]]
local Handle = Emitter:extend()
uv.Handle = Handle

-- Wrapper around `uv_close`. Closes the underlying file descriptor of a handle.
function Handle:close()
  if not self.userdata then error("Can't call :close() on non-userdata objects") end
  return native.close(self.userdata)
end

--[[
This is used by Emitters to register with native events when the first listener
is added.
]]
function Handle:addHandlerType(name)
  if not self.userdata then return end
  self:setHandler(name, function (...)
    self:emit(name, ...)
  end)
end

--[[
Set or replace the handler for a native event.  Usually `Emitter:on()` is what
you want, not this.
]]
function Handle:setHandler(name, callback)
  if not self.userdata then error("Can't call :setHandler() on non-userdata objects") end
  return native.setHandler(self.userdata, name, callback)
end

--------------------------------------------------------------------------------

--[[
This is never used directly.  If you want to create a pure Lua stream, subclass
or instantiate `core.iStream`.
]]
local Stream = Handle:extend()
uv.Stream = Stream

function Stream:shutdown(callback)
  return native.shutdown(self.userdata, callback)
end

function Stream:listen(callback)
  return native.listen(self.userdata, callback)
end


function Stream:accept(other_stream)
  return native.accept(self.userdata, other_stream)
end

function Stream:readStart()
  return native.readStart(self.userdata)
end

function Stream:readStop()
  return native.readStop(self.userdata)
end

function Stream:write(chunk, callback)
  return native.write(self.userdata, chunk, callback)
end

Stream.pipe = iStream.pipe

--------------------------------------------------------------------------------

local Tcp = Stream:extend()
uv.Tcp = Tcp

function Tcp:initialize()
  self.userdata = native.newTcp()
end

function Tcp:nodelay(enable)
  return native.tcpNodelay(self.userdata, enable)
end

function Tcp:keepalive(enable, delay)
  return native.tcpKeepalive(self.userdata, enable, delay)
end

function Tcp:bind(host, port)
  return native.tcpBind(self.userdata, host, port)
end

function Tcp:bind6(host, port)
  return native.tcpBind6(self.userdata, host, port)
end

function Tcp:getsockname()
  return native.tcpGetsockname(self.userdata)
end

function Tcp:getpeername()
  return native.tcpGetpeername(self.userdata)
end

function Tcp:connect(ip_address, port)
  return native.tcpConnect(self.userdata, ip_address, port)
end

function Tcp:connect6(ip_address, port)
  return native.tcpConnect6(self.userdata, ip_address, port)
end

--------------------------------------------------------------------------------

local Udp = Handle:extend()
uv.Udp = Udp

function Udp:initialize()
  self.userdata = native.newUdp()
end

function Udp:bind(host, port)
  return native.udpBind(self.userdata, host, port)
end

function Udp:bind6(host, port)
  return native.udpBind6(self.userdata, host, port)
end

function Udp:setMembership(multicast_addr, interface_addr, option)
  return native.udpSetMembership(self.userdata, multicast_addr, interface_addr, option)
end

function Udp:getsockname()
  return native.udpGetsockname(self.userdata)
end

function Udp:send(...)
  return native.udpSend(self.userdata, ...)
end

function Udp:send6(...)
  return native.udpSend6(self.userdata, ...)
end

function Udp:recvStart()
  return native.udpRecvStart(self.userdata)
end

function Udp:recvStop()
  return native.udpRecvStop(self.userdata)
end

--------------------------------------------------------------------------------

local Pipe = Stream:extend()
uv.Pipe = Pipe

function Pipe:initialize(ipc)
  self.userdata = native.newPipe(ipc and 1 or 0)
end

function Pipe:open(fd)
  return native.pipeOpen(self.userdata, fd)
end

function Pipe:bind(name)
  return native.pipeBind(self.userdata, name)
end

function Pipe:connect(name)
  return native.pipeConnect(self.userdata, name)
end

--------------------------------------------------------------------------------

local Tty = Stream:extend()
uv.Tty = Tty

function Tty:initialize(fd, readable)
  self.userdata = native.newTty(fd, readable)
end

function Tty:setMode(mode)
  return native.ttySetMode(self.userdata, mode)
end

function Tty:getWinsize()
  return native.ttyGetWinsize(self.userdata)
end

Tty.resetMode = native.ttyResetMode

--------------------------------------------------------------------------------


local Timer = Handle:extend()
uv.Timer = Timer

function Timer:initialize()
  self.userdata = native.newTimer()
end

-- Timer:start(timeout, interval, callback)
Timer.start = native.timerStart

-- Timer:stop()
Timer.stop = native.timerStop

-- Timer:again()
Timer.again = native.timerAgain

-- Timer:setRepeat(interval)
Timer.setRepeat = native.timerSetRepeat

-- Timer:getRepeat()
Timer.getRepeat = native.timerGetRepeat

--------------------------------------------------------------------------------

local Process = Handle:extend()
uv.Process = Process

function Process:initialize(command, args, options)
  self.stdin = Pipe:new(0)
  self.stdout = Pipe:new(0)
  self.stderr = Pipe:new(0)
  args = args or {}
  options = options or {}

  self.userdata = native.spawn(self.stdin, self.stdout, self.stderr, command, args, options)

  self.stdout:readStart()
  self.stderr:readStart()
  self.stdout:on('end', function ()
    self.stdout:close()
  end)
  self.stderr:on('end', function ()
    self.stderr:close()
  end)
  self:on('exit', function ()
    self.stdin:close()
    self:close()
  end)

end

function Process:kill(signal)
  return native.processKill(self.userdata, signal)
end

--------------------------------------------------------------------------------

local Watcher = Handle:extend()
uv.Watcher = Watcher

function Watcher:initialize(path)
  self.userdata = native.newFsWatcher(path)
end

return uv
