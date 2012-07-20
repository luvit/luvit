#!/usr/bin/env luvit

local setTimeout = require('timer').setTimeout

local DELAY = 100

local body = 'Hello\n'

require('http').createServer(function (req, res)
  req:on('end', function ()
    if req.url == '/1' then
      setTimeout(1 * DELAY, function ()
      res:writeHead(200, {
        ['Content-Length'] = #body,
      })
      res:finish('[111]\n')
      end)
    elseif req.url == '/2' then
      setTimeout(2 * DELAY, function ()
      res:writeHead(200, {
        ['Content-Length'] = #body,
      })
      res:finish('[222]\n')
      end)
    elseif req.url == '/3' then
      setTimeout(3 * DELAY, function ()
      res:writeHead(200, {
        ['Content-Length'] = #body,
      })
      res:finish('[333]\n')
      end)
    elseif req.url == '/4' then
      setTimeout(4 * DELAY, function ()
      res:writeHead(200, {
        ['Content-Length'] = #body,
      })
      res:finish('[444]\n')
      end)
    else
      setTimeout(1 * DELAY, function ()
      res:writeHead(200, {
        ['Content-Length'] = #body,
      })
      res:finish('Hello\n')
      end)
    end
  end)
end):listen(8080)
