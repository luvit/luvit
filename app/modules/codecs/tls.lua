return function (options)
  local tls = {};
  local outerRead, outerWrite
  function tls.decoder(read, write)
    outerRead = read
    error("TODO: Implement tls decoder")
  end
  function tls.encoder(read, write)
    outerWrite = write
    error("TODO: Implement tls encoder")
  end
  return tls
end
