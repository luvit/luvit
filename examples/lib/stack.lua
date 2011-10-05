--
--
-- creationix/Stack ported by dvv, 2011
--
--

local exports = {}
--exports.__index = exports

--
-- handles errors inside stack, both exceptions and soft errors
--
function exports.error_handler(req, res, err)
  if err then
    local reason = err.stack or err
    print('\n' .. reason .. '\n')
    res:write_head(500, {['Content-Type'] = 'text/plain'})
    res:write(reason .. '\n')
    res:finish()
  else
    res:write_head(404, {['Content-Type'] = 'text/plain'})
    res:finish()
  end
end

--
-- given table of middleware layers, returns the function
-- suitable to pass as HTTP request handler
--
function exports.create(layers)
  local error_handler = exports.error_handler
  local handle = error_handler
  for i = #layers,1,-1 do
    local layer = layers[i]
    local child = handle
    handle = function(req, res)
      local status, err = pcall(layer, req, res, function(err)
        if err then return error_handler(req, res, err) end
        child(req, res)
      end)
      if err then error_handler(req, res, err) end
    end
  end
  return handle
end

--
-- given table of middleware layers, creates and returns listening
-- HTTP server.
-- E.g. create_server({layer1,layer2,...}, 3001, '127.0.0.1')
--
function exports.create_server(layers, ...)
  local stack = exports.create(layers)
  local server = require('http').create_server(stack)
  server:listen(...)
  return server
end

--
--  private tests
--
function exports.__test()
  -- test ok
  local stack = exports.create({
    function (req, res, nxt)
      nxt()
    end,
    function (req, res, nxt)
      res.ok()
    end,
  })
  local ok = false;
  stack(nil, {ok = function() print('1. OK') end})
  -- test hard error
  exports.error_handler = function(req, res, err)
    print(err)
  end
  local stack = exports.create({
    function (req, res, nxt)
      error('2. hard error OK')
    end,
    function (req, res, nxt)
      res.ok()
    end,
  })
  stack(nil, nil)
  -- test soft error
  local stack = exports.create({
    function (req, res, nxt)
      nxt('3. soft error OK')
    end,
    function (req, res, nxt)
      res.ok()
    end,
  })
  stack(nil, nil)
end

--[[
-- TODO: perform test if this module is called, not require()d
if not package.preload.stack and exports.__test then
  exports.__test()
end
]]--

-- export module
return exports
