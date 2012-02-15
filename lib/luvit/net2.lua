--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

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

local dns = require('dns')
local timer = require('timer')
local utils = require('utils')
local Emitter = require('core').Emitter
local Stream = require('core').Stream

--[[
The `net` module provides you with an asynchronous network wrapper. It contains
methods for creating both servers and clients (called sockets). You can include
this module with `require('net')`
]]
local net = {}

--[[
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
]]
function net.createServer(options, connectionListener)
  -- TODO: Implement
end

--[[
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
]]
function net.connect(port, host, connectListener)
  -- TODO: Implement
end


--[[
This class is used to create a TCP or UNIX server. A server is a net.Socket that
can listen for new incoming connections.
]]
local Server = Emitter:extend()
net.Server = Server

--[[
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
          server:close();
          server:listen(PORT, HOST);
        end)
      end
    end)

(Note: All sockets in Node set `SO_REUSEADDR` already)

If a path is given instead of a port, then start a UNIX socket server 
listening for connections on the given `path`.

This function is asynchronous.  When the server has been bound,
['listening'](#event_listening_) event will be emitted.
the last parameter `listeningListener` will be added as an listener for the
['listening'](#event_listening_) event.

]]
function Server:listen(port, host, listeningListener)
  -- TODO: Implement
end

--[[
Stop accepting connections for the given number of milliseconds (default is
one second).  This could be useful for throttling new connections against
DoS attacks or other oversubscription.
]]
function Server:pause(msecs)
  -- TODO: Implement
end

--[[
Stops the server from accepting new connections. This function is
asynchronous, the server is finally closed when the server emits a `'close'`
event.
]]
function Server:close()
  -- TODO: Implement
end

--[[
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
]]
function Server:address()
  -- TODO: Implement
end

--[[
Set this property to reject connections when the server's connection count gets
high.
]]
Server.maxConnections = nil

--[[
The number of concurrent connections on the server.
]]
Server.connections = nil

-- TODO: find way to document events in code
--[[
`net.Server` is an `EventEmitter` with the following events:

#### Event: 'listening'

`function () {}`

Emitted when the server has been bound after calling `server.listen`.

#### Event: 'connection'

`function (socket) {}`

Emitted when a new connection is made. `socket` is an instance of
`net.Socket`.

#### Event: 'close'

`function () {}`

Emitted when the server closes.

#### Event: 'error'

`function (exception) {}`

Emitted when an error occurs.  The `'close'` event will be called directly
following this event.  See example in discussion of `server.listen`.
]]

--[[
This object is an abstraction of a TCP or UNIX socket.  `net.Socket`
instances implement a duplex Stream interface.  They can be created by the
user and used as a client (with `connect()`) or they can be created by Node
and passed to the user through the `'connection'` event of a server.
]]
local Socket = Stream:extend()
net.Socket = Socket

--[[
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
]]
function Socket:initialize(options)
  -- TODO: Implement
end

--[[
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
]]
function Socket:connect(port, host, connectListener)
  -- TODO: Implement
end

--[[
`net.Socket` has the property that `socket.write()` always works. This is to
help users get up and running quickly. The computer cannot always keep up
with the amount of data that is written to a socket - the network connection
simply might be too slow. Node will internally queue up the data written to a
socket and send it out over the wire when it is possible. (Internally it is
polling on the socket's file descriptor for being writable).

The consequence of this internal buffering is that memory may grow. This
property shows the number of characters currently buffered to be written.
(Number of characters is approximately equal to the number of bytes to be
written, but the buffer may contain strings, and the strings are lazily
encoded, so the exact number of bytes is not known.)

Users who experience large or growing `bufferSize` should attempt to
"throttle" the data flows in their program with `pause()` and `resume()`.
]]
Socket.bufferSize = nil

--[[
Sends data on the socket. The second parameter specifies the encoding in the
case of a string--it defaults to UTF8 encoding.

Returns `true` if the entire data was flushed successfully to the kernel
buffer. Returns `false` if all or part of the data was queued in user memory.
`'drain'` will be emitted when the buffer is again free.

The optional `callback` parameter will be executed when the data is finally
written out - this may not be immediately.
]]
function Socket:write(data, callback)
  -- TODO: Implement
end

--[[
Half-closes the socket. i.e., it sends a FIN packet. It is possible the
server will still send some data.

If `data` is specified, it is equivalent to calling
`socket:write(data)` followed by `socket.end()`.
]]
function Socket:finish(data, callback)
  -- TODO: Implement
end

--[[
Ensures that no more I/O activity happens on this socket. Only necessary in
case of errors (parse error or so).
]]
function Socket:destroy()
  -- TODO: Implement
end

--[[
Pauses the reading of data. That is, `'data'` events will not be emitted.
Useful to throttle back an upload.
]]
function Socket:pause()
  -- TODO: Implement
end

--[[
Resumes reading after a call to `pause()`.
]]
function Socket:resume()
  -- TODO: Implement
end

--[[
Sets the socket to timeout after `timeout` milliseconds of inactivity on
the socket. By default `net.Socket` do not have a timeout.

When an idle timeout is triggered the socket will receive a `'timeout'`
event but the connection will not be severed. The user must manually `end()`
or `destroy()` the socket.

If `timeout` is 0, then the existing idle timeout is disabled.

The optional `callback` parameter will be added as a one time listener for the
`'timeout'` event.
]]
function Socket:setTimeout(timeout, callback)
  -- TODO: Implement
end

--[[
Disables the Nagle algorithm. By default TCP connections use the Nagle
algorithm, they buffer data before sending it off. Setting `true` for
`noDelay` will immediately fire off data each time `socket.write()` is called.
`noDelay` defaults to `true`.
]]
function Socket:setNoDelay(noDelay)
  -- TODO: Implement
end

--[[
Enable/disable keep-alive functionality, and optionally set the initial
delay before the first keepalive probe is sent on an idle socket.
`enable` defaults to `false`.

Set `initialDelay` (in milliseconds) to set the delay between the last
data packet received and the first keepalive probe. Setting 0 for
initialDelay will leave the value unchanged from the default
(or previous) setting. Defaults to `0`.
]]
function Socket:setKeepAlive(enable, initialDelay)
  -- TODO: Implement
end

--[[
Returns the bound address and port of the socket as reported by the operating
system. Returns a table with two properties, e.g.
`{address = "192.168.57.1", port = 62053}`
]]
function Socket:address()
  -- TODO: Implement
end

--[[
The string representation of the remote IP address. For example,
`'74.125.127.100'` or `'2001:4860:a005::68'`.
]]
function Socket:remoteAddress()
  -- TODO: Implement
end

--[[
The numeric representation of the remote port. For example,
`80` or `21`.
]]
function Socket:remotePort()
  -- TODO: Implement
end

-- The amount of received bytes.
Socket.bytesRead = nil

-- The amount of bytes sent.
Socket.bytesWritten = nil

-- TODO: find way to document events
--[[
`net.Socket` instances are EventEmitters with the following events:

#### Event: 'connect'

`function () { }`

Emitted when a socket connection is successfully established.
See `connect()`.

#### Event: 'data'

`function (data) { }`

Emitted when data is received.  The argument `data` will be a `Buffer` or
`String`.  Encoding of data is set by `socket.setEncoding()`.
(See the [Readable Stream](streams.html#readable_Stream) section for more
information.)

Note that the __data will be lost__ if there is no listener when a `Socket`
emits a `'data'` event.

#### Event: 'end'

`function () { }`

Emitted when the other end of the socket sends a FIN packet.

By default (`allowHalfOpen == false`) the socket will destroy its file
descriptor  once it has written out its pending write queue.  However, by
setting `allowHalfOpen == true` the socket will not automatically `end()`
its side allowing the user to write arbitrary amounts of data, with the
caveat that the user is required to `end()` their side now.


#### Event: 'timeout'

`function () { }`

Emitted if the socket times out from inactivity. This is only to notify that
the socket has been idle. The user must manually close the connection.

See also: `socket.setTimeout()`


#### Event: 'drain'

`function () { }`

Emitted when the write buffer becomes empty. Can be used to throttle uploads.

See also: the return values of `socket.write()`

#### Event: 'error'

`function (exception) { }`

Emitted when an error occurs.  The `'close'` event will be called directly
following this event.

#### Event: 'close'

`function (had_error) { }`

Emitted once the socket is fully closed. The argument `had_error` is a boolean
which says if the socket was closed due to a transmission error.
]]

--[[
Tests if input is an IP address. Returns 0 for invalid strings,
returns 4 for IP version 4 addresses, and returns 6 for IP version 6 addresses.
]]
function net.isIP(input)
  -- TODO: Implement
end

--[[
Returns true if input is a version 4 IP address, otherwise returns false.
]]
function net.isIPv4(input)
  -- TODO: Implement
end

--[[
Returns true if input is a version 6 IP address, otherwise returns false.
]]
function net.isIPv6(input)
  -- TODO: Implement
end

return net
