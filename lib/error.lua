local Error = {}

local error_prototype = error_meta
Error.prototype = error_prototype

-- Used by things inherited from Error
Error.meta = {__index=Error.prototype}

function Error.new(message)
  local err = {
    message = message,
    prototype = error_prototype
  }
  setmetatable(err, error_prototype)
  return err
end

return Error
