function exports.server(app)
  local function encoder(write)
    return function (item)
      error("TODO: implement server.encoder")
    end
  end

  local function decoder(emit)
    return function (chunk)
      error("TODO: implement server.decoder")
    end
  end

  return decoder(app(encoder))
end

function exports.client(app)
  local function encoder(write)
    return function (item)
      error("TODO: implement client.encoder")
    end
  end

  local function decoder(emit)
    return function (chunk)
      error("TODO: implement client.decoder")
    end
  end

  return decoder(app(encoder))
end
