local native = require('uv_native')
local Object = require('core').Object
local Emitter = require('core').Emitter
local iStream = require('core').iStream
local fs = require('fs')

local uv = Object:extend()

--------------------------------------------------------------------------------

--[[
This class is never used directly, but is the inheritance chain of all libuv
objects.
]]
local Handle = Emitter:extend()
uv.Handle = Handle

-- Wrapper around `uv_close`. Closes the underlying file descriptor of a handle.
-- Handle:close()
Handle.close = native.close

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
-- Handle:setHandler(name, callback)
Handle.setHandler = native.setHandler

--------------------------------------------------------------------------------

--[[
This is never used directly.  If you want to create a pure Lua stream, subclass
or instantiate `core.iStream`.
]]
local Stream = Handle:extend()
uv.Stream = Stream

-- Stream:shutdown(callback)
Stream.shutdown = native.shutdown

-- Stream:listen(callback)
Stream.listen = native.listen

-- Stream:accept(other_stream)
Stream.accept = native.accept

-- Stream:readStart()
Stream.readStart = native.readStart

-- Stream:readStop()
Stream.readStop = native.readStop

-- Stream:readStopNoRef()
Stream.readStopNoRef = native.readStopNoRef

-- Stream:pause()
function Stream:pause()
  self:readStop()
end

-- Stream:pauseNoRef()
function Stream:pauseNoRef()
  self:readStopNoRef()
end

-- Stream:resume()
function Stream:resume()
  self:readStart()
end

-- Stream:write(chunk, callback)
Stream.write = native.write

Stream.pipe = iStream.pipe

--------------------------------------------------------------------------------

local Tcp = Stream:extend()
uv.Tcp = Tcp

function Tcp:initialize()
  self.userdata = native.newTcp()
end

-- Tcp:nodelay(enable)
Tcp.nodelay = native.tcpNodelay

-- Tcp:keepalive(enable, delay)
Tcp.keepalive = native.tcpKeepalive

-- Tcp:bind(host, port)
Tcp.bind = native.tcpBind

-- Tcp:bind6(host, port)
Tcp.bind6 = native.tcpBind6

-- Tcp:getsockname()
Tcp.getsockname = native.tcpGetsockname

-- Tcp:getpeername()
Tcp.getpeername = native.tcpGetpeername

-- Tcp:connect(ip_address, port)
Tcp.connect = native.tcpConnect

-- Tcp:connect6(ip_address, port)
Tcp.connect6 = native.tcpConnect6

-- Tcp:writeQueueSize()
Tcp.writeQueueSize = native.writeQueueSize

--------------------------------------------------------------------------------

local Udp = Handle:extend()
uv.Udp = Udp

function Udp:initialize()
  self.userdata = native.newUdp()
end

-- Udp:bind(host, port)
Udp.bind = native.udpBind

-- Udp:bind6(host, port)
Udp.bind6 = native.udpBind6

-- Udp:setMembership(multicast_addr, interface_addr, option)
Udp.setMembership = native.udpSetMembership

-- Udp:getsockname()
Udp.getsockname = native.udpGetsockname

-- Udp:send(...)
Udp.send = native.udpSend

-- Udp:send6(...)
Udp.send6 = native.udpSend6

-- Udp:recvStart()
Udp.recvStart = native.udpRecvStart

-- Udp:recvStop()
Udp.recvStop = native.udpRecvStop

--------------------------------------------------------------------------------

local Pipe = Stream:extend()
uv.Pipe = Pipe

function Pipe:initialize(ipc)
  self.userdata = native.newPipe(ipc and 1 or 0)
end

-- Pipe:open(fd)
Pipe.open = native.pipeOpen

-- Pipe:bind(name)
Pipe.bind = native.pipeBind

-- Pipe:connect(name)
Pipe.connect = native.pipeConnect

function Pipe:pause()
  native.unref()
  self:readStop()
end

function Pipe:pauseNoRef()
  native.unref()
  self:readStopNoRef()
end

function Pipe:resume()
  native.ref()
  self:readStart()
end

--------------------------------------------------------------------------------

local Tty = Stream:extend()
uv.Tty = Tty

function Tty:initialize(fd, readable)
  self.userdata = native.newTty(fd, readable)
end

-- Tty:setMode(mode)
Tty.setMode = native.ttySetMode

-- Tty:getWinsize()
Tty.getWinsize = native.ttyGetWinsize

Tty.resetMode = native.ttyResetMode

function Tty:pause()
  native.unref()
  self:readStop()
end

-- TODO: The readStop() implementation assumes a reference is being held. This
-- will go away with a libuv upgrade.
function Tty:pauseNoRef()
  native.unref()
  self:readStopNoRef()
end

function Tty:resume()
  native.ref()
  self:readStart()
end

--------------------------------------------------------------------------------


local Timer = Handle:extend()
uv.Timer = Timer

function Timer:initialize()
  self.userdata = native.newTimer()
  self._active = false
  -- uv_timer_init adds a loop reference. (That is, it calls uv_ref.) This
  -- is not the behavior we want in Luvit. Timers should not increase the
  -- ref count of the loop except when active.
  native.unref()
end

function Timer:_update()
  local was_active = self._active
  self._active = native.timerGetActive(self)
  if was_active == false and self._active == true then
    native.ref()
  elseif was_active == true and self._active == false then
    native.unref()
  end
end

-- Timer:start(timeout, interval, callback)
function Timer:start(timeout, interval, callback)
  native.timerStart(self, timeout, interval, callback)
  self:_update()
end

function Timer:close()
  Handle.close(self)
  if self._active == false then
    native.ref()
  end
end

-- Timer:stop()
function Timer:stop()
  native.timerStop(self)
  self:_update()
end

-- Timer:again()
function Timer:again()
  native.timerAgain(self)
  self:_update()
end

-- Timer:setRepeat(interval)
Timer.setRepeat = native.timerSetRepeat

-- Timer:getRepeat()
Timer.getRepeat = native.timerGetRepeat

-- Timer.now
Timer.now = native.now

--------------------------------------------------------------------------------

local Process = Handle:extend()
uv.Process = Process

uv.createWriteableStdioStream = function(fd)
  local fd_type = native.handleType(fd);
  if (fd_type == "TTY") then
    local tty = Tty:new(fd)
    native.unref()
    return tty
  elseif (fd_type == "FILE") then
    return fs.SyncWriteStream:new(fd)
  elseif (fd_type == "NAMED_PIPE") then
    local pipe = Pipe:new(nil)
    pipe:open(fd)
    native.unref()
    return pipe
  else
    error("Unknown stream file type " .. fd)
  end
end

uv.createReadableStdioStream = function(fd)
  local fd_type = native.handleType(fd);
  local stdin
  if (fd_type == "TTY") then
    stdin = Tty:new(fd)
  elseif (fd_type == "FILE") then
    stdin = fs.createReadStream(nil, {fd = fd})
  elseif (fd_type == "NAMED_PIPE") then
    stdin = Pipe:new(nil)
    stdin:open(fd)
  else
    error("Unknown stream file type " .. fd)
  end

  -- unref the event loop so that we don't block unless the user
  -- wants stdin. This follows node's logic.
  if fd_type ~= "FILE" then
    -- fs.createReadStream returns iStream which is pure lua and doesn't have
    -- pauseNoRef method
    stdin:pauseNoRef()
  end

  return stdin
end

function Process:initialize(command, args, options)
  self.stdin = Pipe:new(nil)
  self.stdin:open(0)
  self.stdout = Pipe:new(nil)
  self.stdout:open(1)
  self.stderr = Pipe:new(nil)
  self.stderr:open(2)
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

-- Process:kill(signal)
Process.kill = native.processKill

--------------------------------------------------------------------------------

local Watcher = Handle:extend()
uv.Watcher = Watcher

function Watcher:initialize(path)
  self.userdata = native.newFsWatcher(path)
end

return uv
