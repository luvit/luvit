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

function Stack.substack(...)
  error("TODO: Implement")
end

function Stack.errorHandler(req, res, err)
  if err then
    res:set_code(500)
    res:finish(tostring(err) .. "\n")
    return
  end
  res:set_code(404)
  res:finish("Not Found\n")
end

return Stack

