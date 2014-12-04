local table = require('table')
local Tcp = require('uv').Tcp
local iStream = require('core').iStream
local newHttpParser = require('http_parser').new
local parseUrl = require('http_parser').parseUrl

local web = {}

local STATUS_CODES = {
  [100] = 'Continue',
  [101] = 'Switching Protocols',
  [102] = 'Processing',                 -- RFC 2518, obsoleted by RFC 4918
  [200] = 'OK',
  [201] = 'Created',
  [202] = 'Accepted',
  [203] = 'Non-Authoritative Information',
  [204] = 'No Content',
  [205] = 'Reset Content',
  [206] = 'Partial Content',
  [207] = 'Multi-Status',               -- RFC 4918
  [300] = 'Multiple Choices',
  [301] = 'Moved Permanently',
  [302] = 'Moved Temporarily',
  [303] = 'See Other',
  [304] = 'Not Modified',
  [305] = 'Use Proxy',
  [307] = 'Temporary Redirect',
  [400] = 'Bad Request',
  [401] = 'Unauthorized',
  [402] = 'Payment Required',
  [403] = 'Forbidden',
  [404] = 'Not Found',
  [405] = 'Method Not Allowed',
  [406] = 'Not Acceptable',
  [407] = 'Proxy Authentication Required',
  [408] = 'Request Time-out',
  [409] = 'Conflict',
  [410] = 'Gone',
  [411] = 'Length Required',
  [412] = 'Precondition Failed',
  [413] = 'Request Entity Too Large',
  [414] = 'Request-URI Too Large',
  [415] = 'Unsupported Media Type',
  [416] = 'Requested Range Not Satisfiable',
  [417] = 'Expectation Failed',
  [418] = 'I\'m a teapot',              -- RFC 2324
  [422] = 'Unprocessable Entity',       -- RFC 4918
  [423] = 'Locked',                     -- RFC 4918
  [424] = 'Failed Dependency',          -- RFC 4918
  [425] = 'Unordered Collection',       -- RFC 4918
  [426] = 'Upgrade Required',           -- RFC 2817
  [500] = 'Internal Server Error',
  [501] = 'Not Implemented',
  [502] = 'Bad Gateway',
  [503] = 'Service Unavailable',
  [504] = 'Gateway Time-out',
  [505] = 'HTTP Version not supported',
  [506] = 'Variant Also Negotiates',    -- RFC 2295
  [507] = 'Insufficient Storage',       -- RFC 4918
  [509] = 'Bandwidth Limit Exceeded',
  [510] = 'Not Extended'                -- RFC 2774
}


function web.createServer(host, port, onRequest)
  if not port then error("port is a required parameter") end
  local server = Tcp:new()
  server:bind(host or "0.0.0.0", port)
  server:listen(function ()
    local client = Tcp:new()
    local done
    server:accept(client)
    client:readStart()
    local currentField, headers, url, request
    local parser = newHttpParser("request", {
      onMessageBegin = function ()
        headers = {}
      end,
      onUrl = function (value)
        url = parseUrl(value)
      end,
      onHeaderField = function (field)
        currentField = field
      end,
      onHeaderValue = function (value)
        headers[currentField:lower()] = value
      end,
      onHeadersComplete = function (info)
        request = setmetatable(info, iStream.meta)
        request.url = url
        request.headers = headers
        request.parser = parser
        onRequest(request, function (statusCode, headers, body)
          local reasonPhrase = STATUS_CODES[statusCode] or 'unknown'
          if not reasonPhrase then error("Invalid response code " .. tostring(statusCode)) end

          local head = {"HTTP/1.1 " .. tostring(statusCode) .. " " .. reasonPhrase .. "\r\n"}
          for key, value in pairs(headers) do
            table.insert(head, key .. ": " .. value .. "\r\n")
          end
          table.insert(head, "\r\n")
          if type(body) == "string" then
            table.insert(head, body)
          end
          client:write(table.concat(head))
          if type(body) ~= "table" then
            done(info.should_keep_alive)
          else
            body:on("data", function (chunk)
              client:write(chunk)
            end)
            body:on("end", function ()
              done(info.should_keep_alive)
            end)
          end
        end)
      end,
      onBody = function (chunk)
        request:emit("data", chunk)
      end,
      onMessageComplete = function ()
        request:emit("end")
      end
    })
    client:on('data', function (chunk)
      if #chunk == 0 then return end
      local nparsed = parser:execute(chunk, 0, #chunk)
      -- TODO: handle various cases here
    end)
    client:on('end', function ()
      parser:finish()
    end)

    done = function(keepAlive)
      if keepAlive then
        parser:reinitialize("request")
      else
        client:shutdown(function ()
          client:close()
        end)
      end
    end


  end)
  return server
end

return web