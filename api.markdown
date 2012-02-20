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

### core.iStream

Inherits from `core.Emitter`

This is an abstract interface that works like `uv.Stream` but doesn't actually
contain a uv struct (it's pure lua)

#### iStream:pipe(target)

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

## module

### module.require(filepath, dirname)

## net2

The `net` module provides you with an asynchronous network wrapper. It contains
methods for creating both servers and clients (called sockets). You can include
this module with `require('net')`

### net2.Server

Inherits from `Emitter`

This class is used to create a TCP or UNIX server. A server is a net.Socket that
can listen for new incoming connections.

#### Server:address()

Returns the bound address and port of the server as reported by the operating system.
Useful to find which port was assigned when giving getting an OS-assigned address.
Returns an object with two properties, e.g. `{"address":"127.0.0.1", "port":2121}`

Example:

    local server = net.createServer(function (socket)
      socket:end("goodbye\n")
    end)

    -- grab a random port.
    server:listen(function ()
      local address = server:address()
      debug("opened server on", address)
    end)

Don't call `server:address()` until the `'listening'` event has been emitted.

#### Server:close()

Stops the server from accepting new connections. This function is
asynchronous, the server is finally closed when the server emits a `'close'`
event.

#### Server:listen(port, host, listeningListener)

Begin accepting connections on the specified `port` and `host`.  If the
`host` is omitted, the server will accept connections directed to any
IPv4 address (`INADDR_ANY`). A port value of zero will assign a random port.

This function is asynchronous.  When the server has been bound,
['listening'](#event_listening_) event will be emitted.
the last parameter `listeningListener` will be added as an listener for the
['listening'](#event_listening_) event.

One issue some users run into is getting `EADDRINUSE` errors. This means that
another server is already running on the requested port. One way of handling this
would be to wait a second and then try again. This can be done with

    server:on('error', function (e)
      if e.code == 'EADDRINUSE' then
        print('Address in use, retrying...')
        timer.setTimeout(1000, function ()
          server:close()
          server:listen(PORT, HOST)
        end)
      end
    end)

(Note: All sockets in Luvit set `SO_REUSEADDR` already)

If a path is given instead of a port, then start a UNIX socket server 
listening for connections on the given `path`.

This function is asynchronous.  When the server has been bound,
['listening'](#event_listening_) event will be emitted.
the last parameter `listeningListener` will be added as an listener for the
['listening'](#event_listening_) event.


#### Server:pause(msecs)

Stop accepting connections for the given number of milliseconds (default is
one second).  This could be useful for throttling new connections against
DoS attacks or other oversubscription.

### net2.Socket

Inherits from `uv.Stream`

This object is an abstraction of a TCP or UNIX socket.  `net.Socket`
instances implement a duplex Stream interface.  They can be created by the
user and used as a client (with `connect()`) or they can be created by Luvit
and passed to the user through the `'connection'` event of a server.

#### Socket:address()

Returns the bound address and port of the socket as reported by the operating
system. Returns a table with two properties, e.g.
`{address = "192.168.57.1", port = 62053}`

#### Socket:connect(port, host, connectListener)

Opens the connection for a given socket. If `port` and `host` are given,
then the socket will be opened as a TCP socket, if `host` is omitted,
`localhost` will be assumed. If a `path` is given, the socket will be
opened as a unix socket to that path.

Normally this method is not needed, as `net.createConnection` opens the
socket. Use this only if you are implementing a custom Socket or if a
Socket is closed and you want to reuse it to connect to another server.

This function is asynchronous. When the ['connect'](#event_connect_) event is
emitted the socket is established. If there is a problem connecting, the
`'connect'` event will not be emitted, the `'error'` event will be emitted with
the exception.

The `connectListener` parameter will be added as an listener for the
['connect'](#event_connect_) event.

#### Socket:destroy()

Ensures that no more I/O activity happens on this socket. Only necessary in
case of errors (parse error or so).

#### Socket:finish(data, callback)

Half-closes the socket. i.e., it sends a FIN packet. It is possible the
server will still send some data.

If `data` is specified, it is equivalent to calling
`socket:write(data)` followed by `socket.end()`.

#### Socket:initialize(options)

Construct a new socket object.

`options` is an object with the following defaults:

    {
      fd = nil,
      type = nil,
      allowHalfOpen = false
    }

`fd` allows you to specify the existing file descriptor of socket. `type`
specified underlying protocol. It can be `'tcp4'`, `'tcp6'`, or `'unix'`.
About `allowHalfOpen`, refer to `createServer()` and `'end'` event.

#### Socket:pause()

Pauses the reading of data. That is, `'data'` events will not be emitted.
Useful to throttle back an upload.

#### Socket:remoteAddress()

The string representation of the remote IP address. For example,
`'74.125.127.100'` or `'2001:4860:a005::68'`.

#### Socket:remotePort()

The numeric representation of the remote port. For example,
`80` or `21`.

#### Socket:resume()

Resumes reading after a call to `pause()`.

#### Socket:setKeepAlive(enable, initialDelay)

Enable/disable keep-alive functionality, and optionally set the initial
delay before the first keepalive probe is sent on an idle socket.
`enable` defaults to `false`.

Set `initialDelay` (in milliseconds) to set the delay between the last
data packet received and the first keepalive probe. Setting 0 for
initialDelay will leave the value unchanged from the default
(or previous) setting. Defaults to `0`.

#### Socket:setNoDelay(noDelay)

Disables the Nagle algorithm. By default TCP connections use the Nagle
algorithm, they buffer data before sending it off. Setting `true` for
`noDelay` will immediately fire off data each time `socket.write()` is called.
`noDelay` defaults to `true`.

#### Socket:setTimeout(timeout, callback)

Sets the socket to timeout after `timeout` milliseconds of inactivity on
the socket. By default `net.Socket` do not have a timeout.

When an idle timeout is triggered the socket will receive a `'timeout'`
event but the connection will not be severed. The user must manually `end()`
or `destroy()` the socket.

If `timeout` is 0, then the existing idle timeout is disabled.

The optional `callback` parameter will be added as a one time listener for the
`'timeout'` event.

#### Socket:write(data, callback)

Sends data on the socket. The second parameter specifies the encoding in the
case of a string--it defaults to UTF8 encoding.

Returns `true` if the entire data was flushed successfully to the kernel
buffer. Returns `false` if all or part of the data was queued in user memory.
`'drain'` will be emitted when the buffer is again free.

The optional `callback` parameter will be executed when the data is finally
written out - this may not be immediately.

### net2.connect(port, host, connectListener)

Construct a new socket object and opens a socket to the given location. When the
socket is established the `connect` event will be emitted.

The arguments for these methods change the type of connection:

 - `net.connect(port, [host], [connectListener])` - Creates a TCP connection to
   port on host. If host is omitted, 'localhost' will be assumed.

 - `net.connect(path, [connectListener])` - Creates unix socket connection to
   `path`.

The connectListener parameter will be added as an listener for the `connect`
event.

Here is an example of a client of echo server as described previously:

    local net = require 'net'
    local client = net.connect(8124, function ()
      debug('on_connect')
      client:write('world!\r\n')
    end)
    client:on('data', function (data) 
      debug('on_data', data)
      client:end()
    end)
    client:on('end', function ()
      debug('on_end')
    end)

To connect on the socket `/tmp/echo.sock` the second line would just be changed to

    local client = net.connect('/tmp/echo.sock', function ()

### net2.createServer(options, connectionListener)

Creates a new TCP server. The `connectionListener` argument is automatically set
as a listener for the `connection` event.

`options` is a table with the following defaults:

    { allowHalfOpen = false }

If `allowHalfOpen` is `true`, then the socket won't automatically send a FIN
packet when the other end of the socket sends a FIN packet. The socket becomes
non-readable, but still writable. You should call the `end()` method explicitly.
See `end` event for more information.

Here is an example of a echo server which listens for connections
on port 8124:

    local net = require('net')
    local server = net.createServer(function (c) { //'connection' listener
      debug('server connected')
      c:on('end', function ()
        debug('client disconnected')
      end)
      c:write('hello\r\n')
      c:pipe(c)
    end)
    server:listen(8124, function () {
      print('server bound')
    end)

Test this by using `telnet`:

    telnet localhost 8124

To listen on the socket `/tmp/echo.sock` the third line from the last would
just be changed to

    server:listen('/tmp/echo.sock', function (c) {

Use `nc` to connect to a UNIX domain socket server:

    nc -U /tmp/echo.sock

## net

### net.Server

Inherits from `Emitter`

#### Server:close()

#### Server:initialize(...)

#### Server:listen(port, ... --[[ ip, callback --]] )

### net.Socket

Inherits from `Emitter`

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

## timer

### timer.clearTimer(timer)

### timer.setInterval(period, callback, ...)

### timer.setTimeout(duration, callback, ...)

## url

### url.parse(url)

## utils

### utils.bind(fun, self, ...)

### utils.color(color_name)

### utils.colorize(color_name, string, reset_name)

### utils.debug(...)

Like p, but prints to stderr using blocking I/O for better debugging

### utils.dump(o, depth)

### utils.prettyPrint(...)

A nice global data dumper

### utils.print(...)

Replace print

## uv

Inherits from `core.Object`

### uv.Handle

Inherits from `Emitter`

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

### uv.Pipe

Inherits from `uv.Stream`

#### Pipe:bind(name)

#### Pipe:connect(name)

#### Pipe:initialize(ipc)

#### Pipe:open(fd)

### uv.Process

Inherits from `uv.Handle`

#### Process:initialize(command, args, options)

#### Process:kill(signal)

### uv.Stream

Inherits from `uv.Handle`

This is never used directly.  If you want to create a pure Lua stream, subclass
or instantiate `core.iStream`.

#### Stream:accept(other_stream)

#### Stream:listen(callback)

#### Stream:readStart()

#### Stream:readStop()

#### Stream:shutdown(callback)

#### Stream:write(chunk, callback)

### uv.Tcp

Inherits from `uv.Stream`

#### Tcp:bind(host, port)

#### Tcp:bind6(host, port)

#### Tcp:connect(ip_address, port)

#### Tcp:connect6(ip_address, port)

#### Tcp:getpeername()

#### Tcp:getsockname()

#### Tcp:initialize()

#### Tcp:keepalive(enable, delay)

#### Tcp:nodelay(enable)

### uv.Timer

Inherits from `uv.Handle`

#### Timer:again()

#### Timer:getRepeat()

#### Timer:initialize()

#### Timer:setRepeat(interval)

#### Timer:start(timeout, interval, callback)

#### Timer:stop()

### uv.Tty

Inherits from `uv.Stream`

#### Tty:getWinsize()

#### Tty:initialize(fd, readable)

#### Tty:setMode(mode)

### uv.Udp

Inherits from `uv.Handle`

#### Udp:bind(host, port)

#### Udp:bind6(host, port)

#### Udp:getsockname()

#### Udp:initialize()

#### Udp:recvStart()

#### Udp:recvStop()

#### Udp:send(...)

#### Udp:send6(...)

#### Udp:setMembership(multicast_addr, interface_addr, option)

### uv.Watcher

Inherits from `uv.Handle`

#### Watcher:initialize(path)

