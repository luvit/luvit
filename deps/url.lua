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
exports.version = "1.0.4-2"
exports.dependencies = {
  "luvit/querystring@1.0.1",
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/url.lua"
exports.description = "Node-style url codec for luvit"
exports.tags = {"luvit", "url", "codec"}

local querystring = require('querystring')

function exports.parse(url, parseQueryString)
  local href = url
  local chunk, protocol = url:match("^(([a-z0-9+]+)://)")
  url = url:sub((chunk and #chunk or 0) + 1)

  local auth
  chunk, auth = url:match('(([0-9a-zA-Z]+:?[0-9a-zA-Z]+)@)')
  url = url:sub((chunk and #chunk or 0) + 1)

  local host
  local hostname
  local port
  if protocol then
    host = url:match("^([%a%.%d-]+:?%d*)")
    if host then
      hostname = host:match("^([^:/]+)")
      port = host:match(":(%d+)$")
    end
  url = url:sub((host and #host or 0) + 1)
  end

  host = hostname -- Just to be compatible with our code base. Discuss this.

  local path
  local pathname
  local search
  local query
  local hash
  hash = url:match("(#.*)$")
  url = url:sub(1, (#url - (hash and #hash or 0)))

  if url ~= '' then
    path = url
    local temp
    temp = url:match("^[^?]*")
    if temp ~= '' then
      pathname = temp
    end
    temp = url:sub((pathname and #pathname or 0) + 1)
    if temp ~= '' then
      search = temp
    end
    if search then
    temp = search:sub(2)
      if temp ~= '' then
        query = temp
      end
    end
  end

  if parseQueryString then
    query = querystring.parse(query)
  end

  return {
    href = href,
    protocol = protocol,
    host = host,
    hostname = hostname,
    port = port,
    path = path or '/',
    pathname = pathname or '/',
    search = search,
    query = query,
    auth = auth,
    hash = hash
  }

end
