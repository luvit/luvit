--[[

Copyright 2015 The Luvit Authors. All Rights Reserved.

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

exports.name = "luvit/url"
exports.version = "0.1.0"

local querystring = require('querystring')

function exports.parse(url, parseQueryString)
  local href = url
  local chunk, protocol = url:match("^(([a-z0-9+]+)://)")
  url = url:sub((chunk and #chunk or 0) + 1)
  local host = url:match("^([^/]+)")
  local hostname, port
  if host then
    hostname = host:match("^([^:/]+)")
    port = host:match(":(%d+)$")
  end

  url = url:sub((host and #host or 0) + 1)
  local pathname = url:match("^[^?]*")
  local search = url:sub((pathname and #pathname or 0) + 1)
  local query = search:sub(2)

  if parseQueryString then
    query = querystring.parse(query)
  end

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

--p(url.parse("http://creationix.com:8080/foo/bar?this=sdr"))
--p(url.parse("http://creationix.com/foo/bar?this=sdr"))
--p(url.parse("http://creationix.com/foo/bar"))
--p(url.parse("http://creationix.com/"))
--p(url.parse("creationix.com/"))
--p(url.parse("/"))
--p(url.parse("/foobar"))
--p(url.parse("/README.markdown"))

