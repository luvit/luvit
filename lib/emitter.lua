local emitter_prototype = {}

function emitter_prototype:once(name, callback)
  local function wrapped(...)
    self:remove_listener(name, wrapped)
    callback(...)
  end
  self:on(name, wrapped)
end

function emitter_prototype:on(name, callback)
  if not self.handlers then self.handlers = {} end
  local handlers = self.handlers
  if not handlers[name] then
    if self == process then
      require("uv").activate_signal_handler(require('constants')[name]);
    elseif self.userdata then
      local emitter = self
      self.userdata:set_handler(name, function (...)
        emitter:emit(name, ...)
      end)
    end
    handlers[name] = {}
  end
  handlers[name][callback] = true
end
emitter_prototype.add_listener = emitter_prototype.on

function emitter_prototype:emit(name, ...)
  if not self.handlers then
    if (name == "error") then error(...) end
    return
  end
  local handlers = self.handlers
  if not handlers[name] then
    if (name == "error") then error(...) end
    return
  end
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
  if handlers[name] then
    if self.userdata then
      self.userdata.set_handler(name, nil)
    end
    handlers[name] = nil
  end
end

local emitter_meta = {__index=emitter_prototype}

local function new()
  local emitter = {}
  setmetatable(emitter, emitter_meta)
  return emitter
end

return {
  new = new,
  prototype = emitter_prototype,
  meta = emitter_meta
}
