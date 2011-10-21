local Constants = require('constants')

local emitter_prototype = {}

-- By default, and error events that are not listened for should thow errors
function emitter_prototype:missing_handler_type(name, ...)
  if name == "error" then
    error(...)
  end
end

-- Sugar for emitters you want to auto-remove themself after first event
function emitter_prototype:once(name, callback)
  local function wrapped(...)
    self:remove_listener(name, wrapped)
    callback(...)
  end
  self:on(name, wrapped)
end

-- Add a new typed event emitter
function emitter_prototype:on(name, callback)
  local handlers = rawget(self, "handlers")
  if not handlers then
    handlers = {}
    rawset(self, "handlers", handlers)
  end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    if self.add_handler_type then
      self:add_handler_type(name)
    end
    handlers_for_type = {}
    rawset(handlers, name, handlers_for_type)
  end
  handlers_for_type[callback] = true
end
emitter_prototype.add_listener = emitter_prototype.on

function emitter_prototype:emit(name, ...)
  local handlers = rawget(self, "handlers")
  if not handlers then
    self:missing_handler_type(name, ...)
    return
  end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    self:missing_handler_type(name, ...)
    return
  end
  for k, v in pairs(handlers_for_type) do
    k(...)
  end
end

function emitter_prototype:remove_listener(name, callback)
  local handlers = rawget(self, "handlers")
  if not handlers then return end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then return end
  handlers_for_type[name][callback] = nil
end

local emitter_meta = {__index=emitter_prototype}

local function new()
  return setmetatable({}, emitter_meta)
end

return {
  new = new,
  prototype = emitter_prototype,
  meta = emitter_meta
}
