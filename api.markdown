## uv

Inherits from `core.Object`

### uv.Handle

Inherits from `Emitter`

This class is never used directly, but is the inheritance chain of all libuv
objects.

#### Handle:addHandlerType(name)

This is used by Emitters to register with native events when the first listener
is added.

### uv.Pipe

Inherits from `uv.Stream`

#### Pipe:initialize(ipc)

### uv.Process

Inherits from `uv.Handle`

#### Process:initialize(command, args, options)

### uv.Stream

Inherits from `uv.Handle`

This is never used directly.  If you want to create a pure Lua stream, subclass
or instantiate `core.iStream`.

### uv.Tcp

Inherits from `uv.Stream`

#### Tcp:initialize()

### uv.Timer

Inherits from `uv.Handle`

#### Timer:initialize()

### uv.Tty

Inherits from `uv.Stream`

#### Tty:initialize(fd, readable)

### uv.Udp

Inherits from `uv.Handle`

#### Udp:initialize()

### uv.Watcher

Inherits from `uv.Handle`

#### Watcher:initialize(path)

istening'` event has been emitted.

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
`socket:write(data)` followed by `socket:finish()`.

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
    local server = net.createServer(function (c)  -- 'connection' listener
      debug('server connected')
      c:on('end', function ()
        debug('client disconnected')
      end)
      c:write('hello\r\n')
      c:pipe(c)
    end)
    server:listen(8124, function () 
      print('server bound')
    end)

Test this by using `telnet`:

    telnet localhost 8124

To listen on the socket `/tmp/echo.sock` the third line from the last would
just be changed to

    server:listen('/tmp/echo.sock', function (c) {

Use `nc` to connect to a UNIX domain socket server:

    nc -U /tmp/echo.sock

