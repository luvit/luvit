#!/usr/bin/env luvit

local Stack = require('lib/stack')

function stack()
  return {
    --[[function (req, res, nxt)
      --error('AAA')
      nxt()
    end,]]--
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      local s = ('Привет, Мир') --:rep(100)
      res:write_head(200, {
        ['Content-Type'] = 'text/plain',
        ['Content-Length'] = s:len()
      })
      res:write(s)
      res:finish()
    end
  }
end

Stack.create_server(stack(), 65401)
Stack.create_server(stack(), 65402)
Stack.create_server(stack(), 65403)
Stack.create_server(stack(), 65404)

print('Server listening at http://localhost:65401/')
