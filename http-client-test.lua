local uv = require('uv')
local wrapStream = require('codec').wrapStream
local chain = require('codec').chain
local clientCodec = require('http-codec').client

uv.getaddrinfo("luvit.io", "http", {
  socktype = "STREAM",
  family = "INET",
}, function (err, res)
  assert(not err, err)
  local client = uv.new_tcp()
  uv.tcp_connect(client, res[1].addr, res[1].port, function (err)
    assert(not err, err)
    p {
      client = client,
      sock = uv.tcp_getsockname(client),
      peer = uv.tcp_getpeername(client),
    }
    local read, write = wrapStream(client)
    chain(clientCodec.decoder, function (read, write)
      local req = { method = "GET", path = "/", headers = {
        {"Host", "luvit.io"},
        {"User-Agent", "luvit"},
        {"Accept", "*/*"},
      }}
      p(req)
      write(req)
      local res = read()
      p(res)
      write()
    end, clientCodec.encoder)(read, write)
  end)
end)


-- local client = uv.new_tcp()
-- uv.tcp_connect

--       { method = "GET", path = "/orgs/luvit", headers = {
--         {"User-Agent", "Luvit Unit Tests"},
--         {"Host", "api.github.com"},
--         {"Accept", "*/*"},
--         {"Authorization", "token 6d2fc6ae08215d69d693f5ca76ea87c7780a4275"},
--       }}
