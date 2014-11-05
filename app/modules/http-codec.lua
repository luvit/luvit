local server = {}
local client = {}
exports.server = server
exports.client = client

function server.encoder(write)
  return function (item)
    error("TODO: implement server.encoder")
  end
end

function client.encoder(write)
  return function (item)
    error("TODO: implement client.encoder")
  end
end

function client.decoder(emit)
  return function (chunk)
    error("TODO: implement client.decoder")
  end
end

function server.decoder(emit)
  return function (chunk)
    error("TODO: implement server.decoder")
  end
end
