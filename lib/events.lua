local emitter_prototype = {}

function emitter_prototype:on(name, callback)
  if not self.handlers then self.handlers = {} end
  local handlers = self.handlers
  if not handlers[name] then handlers[name] = {} end
  handlers[name][callback] = true
end
emitter_prototype.add_listener = emitter_prototype.on

function emitter_prototype:emit(name, ...)
  if not self.handlers then return end
  local handlers = self.handlers
  if not handlers[name] then return end
  for k, v in pairs(handlers[name]) do
    k(...)
  end
end

function emitter_prototype:remove_listener(name, callback)
  if not self.handlers then return end
  local handlers = self.handlers
  if not handlers[name] then return end
  handlers[name][callback] = nil
end

function emitter_prototype:remove_listeners(name)
  if not self.handlers then return end
  local handlers = self.handlers
  handlers[name] = nil
end

local function new_event_emitter()
  local emitter = {}
  setmetatable(emitter, {__index=emitter_prototype})
  return emitter
end

return {
  new_event_emitter = new_event_emitter
}
