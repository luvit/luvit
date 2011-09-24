local uv = require('uv')

-- Simple TCP server
function create_server(on_connection)
  local server = uv.new_tcp()
  return {
    listen = function (port, host)
      p(host or "0.0.0.0", port)
      server:bind(host or "0.0.0.0", port)
      server:listen(function (status)
        local client = uv.new_tcp()
        server:accept(client)
        client:read_start()
        on_connection(client)
      end)
    end
  }
end

-- Export the module
return {
  create_server = create_server
}
