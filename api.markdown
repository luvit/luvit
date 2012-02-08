## buffer

### buffer.Buffer

Inherits from `Object`

#### Buffer:initialize(length)

#### Buffer:inspect()

#### Buffer:readInt16BE(offset)

#### Buffer:readInt16LE(offset)

#### Buffer:readInt32BE(offset)

#### Buffer:readInt32LE(offset)

#### Buffer:readInt8(offset)

#### Buffer:readUInt16BE(offset)

#### Buffer:readUInt16LE(offset)

#### Buffer:readUInt32BE(offset)

#### Buffer:readUInt32LE(offset)

#### Buffer:readUInt8(offset)

## childprocess

### childprocess.Process

Inherits from `core.Handle`

#### Process:initialize(command, args, options)

#### Process:kill(signal)

### childprocess.execFile(command, args, options, callback)

### childprocess.spawn(command, args, options)

## core

This module is for various classes and utilities that don't need their own
module.

### core.Emitter

Inherits from `core.Object`

This class can be used directly whenever an event emitter is needed.

    local emitter = Emitter:new()
    emitter:on('foo', p)
    emitter:emit('foo', 1, 2, 3)

Also it can easily be sub-classed.

    local Custom = Emitter:extend()
    local c = Custom:new()
    c:on('bar', onBar)

#### Emitter:emit(name, ...)

Emit a named event to all listeners with optional data argument(s).

#### Emitter:missingHandlerType(name, ...)

By default, and error events that are not listened for should thow errors

#### Emitter:on(name, callback)

Adds an event listener (`callback`) for the named event `name`.

#### Emitter:once(name, callback)

Same as `Emitter:on` except it de-registers itself after the first event.

#### Emitter:removeListener(name, callback)

Remove a listener so that it no longer catches events.

#### Emitter:wrap(name)

Utility that binds the named method `self[name]` for use as a callback.  The
first argument (`err`) is re-routed to the "error" event instead.

    local Joystick = Emitter:extend()
    function Joystick:initialize(device)
      self:wrap("onOpen")
      FS.open(device, self.onOpen)
    end

    function Joystick:onOpen(fd)
      -- and so forth
    end

### core.Error

Inherits from `core.Object`

This is for code that wants structured error messages.

#### Error:initialize(message)

### core.Handle

Inherits from `core.Emitter`

This class is never used directly, but is the inheritance chain of all libuv
objects.

#### Handle:addHandlerType(name)

This is used by Emitters to register with native events when the first listener
is added.

#### Handle:close()

Wrapper around `uv_close`. Closes the underlying file descriptor of a handle.

#### Handle:setHandler(name, callback)

Set or replace the handler for a native event.  Usually `Emitter:on()` is what
you want, not this.

### core.Object

This is the most basic object in Luvit. It provides simple prototypal
inheritance and inheritable constructors. All other objects inherit from this.

#### Object:create()

Create a new instance of this object

#### Object:extend()

Creates a new sub-class.

    local Square = Rectangle:extend()
    function Square:initialize(w)
      self.w = w
      self.h = h
    end

#### Object:new(...)

Creates a new instance and calls `obj:initialize(...)` if it exists.

    local Rectangle = Object:extend()
    function Rectangle:initialize(w, h)
      self.w = w
      self.h = h
    end
    function Rectangle:getArea()
      return self.w * self.h
    end
    local rect = Rectangle:new(3, 4)
    p(rect:getArea())

### core.Stream

Inherits from `core.Handle`

This is never used directly.  If you want to create a pure Lua stream, subclass
or instantiate `core.iStream`.

#### Stream:accept(other_stream)

#### Stream:listen(callback)

#### Stream:pipe(target)

#### Stream:readStart()

#### Stream:readStop()

#### Stream:shutdown(callback)

#### Stream:write(chunk, callback)

### core.iStream

Inherits from `core.Emitter`

This is an abstract interface that works like `core.Stream` but doesn't actually
contain a uv struct (it's pure lua)

## dns

### dns.isIp(ip)

### dns.isIpV4(ip)

### dns.isIpV6(ip)

### dns.lookup(domain, family, callback)

### dns.resolve(domain, rrtype, callback)

### dns.resolve4(domain, callback)

### dns.resolve6(domain, callback)

### dns.resolveCname(domain, callback)

### dns.resolveMx(domain, callback)

### dns.resolveNs(domain, callback)

### dns.resolveSrv(domain, callback)

### dns.resolveTxt(domain, callback)

### dns.reverse(ip, callback)

### fiber.new(fn)

## fs

### fs.Watcher

Inherits from `core.Handle`

#### Watcher:initialize(path)

### fs.createReadStream(path, options)

TODO: Implement backpressure here and in tcp streams

### fs.createWriteStream(path, options)

### fs.exists(path, callback)

### fs.existsSync(path)

### fs.readFile(path, callback)

### fs.readFileSync(path)

### fs.writeFile(path, data, callback)

### fs.writeFileSync(path, data)

### http.Request

Inherits from `core.iStream`

#### Request:close(...)

#### Request:initialize(socket)

### http.Response

Inherits from `core.iStream`

#### Response:addHeader(name, value)

allows duplicate headers.  Returns the index it was inserted at

#### Response:close(...)

#### Response:finish(chunk, callback)

#### Response:flushHead(callback)

#### Response:initialize(socket)

#### Response:setCode(code)

#### Response:setHeader(name, value)

This sets a header, replacing any header with the same name (case insensitive)

#### Response:unsetHeader(name)

Removes a set header.  Cannot remove headers added with :addHeader

#### Response:write(chunk, callback)

#### Response:writeContinue(callback)

#### Response:writeHead(code, headers, callback)

### http.createServer(host, port, onConnection)

### http.request(options, callback)

## json = {

### json.parse(string, options)

### json.streamingParser(callback, options)

### json.stringify(value, options)

## mime

### mime.getType(path)

## net

### net.Server

Inherits from `core.Emitter`

#### Server:close()

#### Server:initialize(...)

#### Server:listen(port, ... --[[ ip, callback --]] )

### net.Socket

Inherits from `core.Emitter`

#### Socket:_connect(address, port, addressType)

#### Socket:close()

#### Socket:connect(port, host, callback)

#### Socket:initialize()

#### Socket:pipe(destination)

#### Socket:setTimeout(msecs, callback)

#### Socket:write(data, callback)

### path.basename(filepath, expected_ext)

### path.dirname(filepath)

### path.extname(filepath)

### path.join(...)

### path.normalize(filepath)

### path.resolve(root, filepath)

## pipe

### pipe.Pipe

Inherits from `Stream`

#### Pipe:bind(name)

#### Pipe:connect(name)

#### Pipe:initialize(ipc)

#### Pipe:open(fd)

## querystring

querystring helpers

### querystring.parse(str, sep, eq)

parse querystring into table. urldecode tokens

### querystring.urldecode(str)

### querystring.urlencode(str)

### repl.evaluateLine(line)

### repl.start()

### stack.compose(...)

Build a composite stack made of several layers

### stack.errorHandler(req, res, err)

### stack.mount(mountpoint, ...)

Mounts a substack app at a url subtree

### stack.stack(...)

### stack.translate(mountpoint, matchpoint, ...)

## tcp

### tcp.Tcp

Inherits from `Stream`

#### Tcp:bind(host, port)

#### Tcp:bind6(host, port)

#### Tcp:connect(ip_address, port)

#### Tcp:connect6(ip_address, port)

#### Tcp:getpeername()

#### Tcp:getsockname()

#### Tcp:initialize()

#### Tcp:keepalive(enable, delay)

#### Tcp:nodelay(enable)

## timer

### timer.Timer

Inherits from `Handle`

#### Timer:again()

#### Timer:getRepeat()

#### Timer:initialize()

#### Timer:setRepeat(interval)

#### Timer:start(timeout, interval, callback)

#### Timer:stop()

### timer.clearTimer(timer)

### timer.setInterval(period, callback, ...)

### timer.setTimeout(duration, callback, ...)

## tty

### tty.Tty

Inherits from `Stream`

#### Tty:getWinsize()

#### Tty:initialize(fd, readable)

#### Tty:setMode(mode)

### tty.resetMode()

## udp

### udp.Udp

Inherits from `Handle`

#### Udp:bind(host, port)

#### Udp:bind6(host, port)

#### Udp:getsockname()

#### Udp:initialize()

#### Udp:recvStart()

#### Udp:recvStop()

#### Udp:send(...)

#### Udp:send6(...)

#### Udp:setMembership(multicast_addr, interface_addr, option)

## url

### url.parse(url)

## utils

### utils.bind(fun, self, ...)

### utils.color(color_name)

### utils.colorize(color_name, string, reset_name)

### utils.dump(o, depth)

