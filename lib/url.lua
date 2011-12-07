local Url = {}

function Url.parse(url)
  local href = url
  local chunk, protocol = url:match("^(([a-z0-9+]+)://)")
  url = url:sub((chunk and #chunk or 0) + 1)
  local host = url:match("^([^/]+)")
  if host then
    local hostname = host:match("^([^:/]+)")
    local port = host:match(":(%d+)$")
  end

  url = url:sub((host and #host or 0) + 1)
  local pathname = url:match("^[^?]*")
  local search = url:sub((pathname and #pathname or 0) + 1)
  local query = search:sub(2)
  
  return {
    href = href,
    protocol = protocol,
    host = host,
    hostname = hostname,
    port = port,
    pathname = pathname,
    search = search,
    query = query
  }
end

--p(Url.parse("http://creationix.com:8080/foo/bar?this=sdr"))
--p(Url.parse("http://creationix.com/foo/bar?this=sdr"))
--p(Url.parse("http://creationix.com/foo/bar"))
--p(Url.parse("http://creationix.com/"))
--p(Url.parse("creationix.com/"))
--p(Url.parse("/"))
--p(Url.parse("/foobar"))
--p(Url.parse("/README.markdown"))

return Url
