# HTTP-Cluster

This is a high-performance HTTP server using the `uv` library directly.  It uses `http-encoder` and `http-decoder` to implement the http encoding and decoding on the tcp stream.

## Usage

To run this, simply run the `master.lua` file with luvit.

```sh
luvit master.lua
```

You can benchmark this server using ab or [wrk](https://github.com/wg/wrk).

```sh
ab -t 5 -c 1000 -k http://127.0.0.1:8080/
```

## How clustering works.

First the clustering is done with a simple, but powerful unix trick.  This
will not work on windows, sorry.  The master process (`master.lua`) will
create a normal TCP server and bind to port `8080` on `127.0.0.1`.  But it
won't listen for or accept any connections.

```lua
-- Create
local server = uv.new_tcp()
uv.tcp_bind(server, "127.0.0.1", 8080)
```

Instead it creates a special pipe with fd-passing enabled.  Then it spawns a
child per cpu core and passes the tcp handle to each child over the pipe as
the child's fd 3.

```lua
for i = 1, #uv.cpu_info() do
  -- Create the special pipe
  local pipe = uv.new_pipe(true)
  local child, pid
  -- Create the child
  child, pid = uv.spawn(uv.exepath(), {
    args = {workerPath},
    stdio = {0,1,2,pipe},
  }, onClose)
  -- Send the server handle
  uv.write2(pipe, ".", server, onWrite)
end
```

The children look like normal tcp servers, except they don't bind to the port.
Instead they read from the special pipe their parent gave them and accept the
server handle.

```lua
local server = uv.new_tcp()
local pipe = uv.new_pipe(true)
uv.pipe_open(pipe, 3)
uv.read_start(pipe, function (err)
  assert(not err, err)
  if uv.pipe_pending_count(pipe) > 0 then
    assert(uv.pipe_pending_type(pipe) == "TCP")
    uv.accept(pipe, server)
    uv.close(pipe)
  end
end)
```

Then it's business as usual with listen and accept when a client connects.

```lua
uv.listen(server, 256, function (err)
  assert(not err, err)
  local client = uv.new_tcp()
  uv.accept(server, client)
  -- Do things with client
end)
```

This means that all the child processes are listening at the same time on the
same port.  Under high-load, the first worker in the cluster may be busy and
another will beat it to the request.  This creates for automatic load
distribution across the workers.  There is no proxy going on here.  The
requests are directly going to the workers with the kernel doing all the work
to distribute it.

## How HTTP works

First the uv socket is wrapped to a new streaming interface that exposes a
blocking read and write.  When I say "blocking", I mean it suspends the
current coroutine if I/O wait needs to happen and resumes it later when the
I/O completes.  The main thread is not actually blocked, only the local
coroutine.

```lua
local wrapStream = require('codec').wrapStream

-- `client` is the tcp handle that was accepted in the listen callback.
-- Here we're wrapping it to expose a blocking read and write interface.
local read, write = wrapStream(client)
```

The HTTP protocol is implemented as a pure-lua library in luvit known as
`codecs/http`.  This is platform agnostic code that can actually be used in any
lua project.  Basically it's implemented as two stream processors.  The first
lives between the raw TCP packets and the user's app.  It decodes the packets
and writes request objects and body chunk values.  The user app reads from
this and writes responses to an encoder that also sits between the user and
the tcp socket, but on the other side.

```lua
local function app(read, write)
  -- Keep processing requests on this tcp socket till it's closed
  for req in read do
    -- To something with req to process this new request
    print(req.method, req.url)

    -- Consume the request body
    repeat
      local chunk = read()
    until not chunk or chunk == ""

    local body = req.path .. "\n"
    local head = {
      code = 200,
      { "Server", "Luvit" },
      { "Content-Type", "text/plain" },
      { "Content-Length", #body },
    }
    if req.keepAlive then
      head[#head + 1] = { "Connection", "Keep-Alive" }
    end

    -- Write the response headers and body
    write(head)
    write(body)

    -- If the request didn't support keepalive, we should break the loop
    if not req.keepAlive then
      break
    end
  end
  -- Writing nil closes the connection
  write()
end
```

Then we hook up the adapted `uv_tcp_t` socket with the user code that also
uses the read/write interface and insert the http codec in the middle with the
chain helper.

```lua
local chain = require('codec').chain

chain(httpServer.decoder, app, httpServer.encoder)(read, write)
```
