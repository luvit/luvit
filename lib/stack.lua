local Url = require('url')
local Stack = {}

function Stack.stack(...)
  local error_handler = Stack.errorHandler
  local handle = error_handler

  local layers  = {...}
  for i = #layers, 1, -1 do
    local layer = layers[i]
    local child = handle
    handle = function(req, res)
      local success, err = pcall(function ()
        layer(req, res, function (err)
          if err then return error_handler(req, res, err) end
          child(req, res)
        end)
      end)
      if not success and err then
        error_handler(req, res, err)
      end
    end
  end

  return handle
end

local function core(req, res, continue) continue() end

-- Build a composite stack made of several layers
function Stack.compose(...)
  local layers = {...}

  -- Don't bother composing singletons
  if #layers == 1 then return layers[1] end

  local stack = core
  for i = #layers, 1, -1 do
    local layer = layers[i]
    local child = stack
    stack = function (req, res, continue)
      local success, err = pcall(function ()
        layer(req, res, function (err)
          if err then return continue(err) end
          child(req, res, continue)
        end)
      end)
      if not success and err then
        continue(err)
      end
    end
  end

  return stack
end

-- Mounts a substack app at a url subtree
function Stack.mount(mountpoint, ...)

  local stack = Stack.compose(...)

  if mountpoint:sub(#mountpoint) == "/" then
    mountpoint = mountpoint:sub(1, #mountpoint - 1)
  end

  local matchpoint = mountpoint .. "/"

  return function(req, res, continue)
    local url = req.url
    local uri = req.uri

    if not (url:sub(1, #matchpoint) == matchpoint) then return continue() end

    -- Modify the url
    if not req.real_url then req.real_url = url end

    req.url = url:sub(#mountpoint + 1)
    if not req.uri then req.uri = Url.parse(req.url) end

    stack(req, res, function (err)
      req.url = url
      req.uri = uri
      continue(err)
    end)

  end

end

local Debug = require('debug')
function Stack.errorHandler(req, res, err)
  if err then
    res:set_code(500)
    res:finish(Debug.traceback(err) .. "\n")
    return
  end
  res:set_code(404)
  res:finish("Not Found\n")
end

return Stack

