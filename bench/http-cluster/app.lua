return function (read, write)
  for req in read do
    -- print("Writing response headers")
    local body = req.path .. "\n"
    local headers = {
      { "Server", "Luvit" },
      { "Content-Type", "text/plain" },
      { "Content-Length", #body },
    }
    if req.keepAlive then
      headers[#headers + 1] = { "Connection", "Keep-Alive" }
    end

    write {
      code = 200,
      headers = headers
    }
    -- print("Writing body")
    write(body)

    if not req.keepAlive then
      break
    end
  end
  write()
end
