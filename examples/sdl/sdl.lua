local ffi = require('ffi')
local Emitter = require('emitter')
local timer = require('timer')
local fs = require('fs')
local uv = require('uv')

ffi.cdef(fs.readFileSync(__dirname .. '/ffi_SDL.h'))

local SDL = {
}

local lazy = {
  ffi = function () return ffi.load('SDL') end,
  GFX = function () return ffi.load("SDL_gfx") end,
  TTF = function () return ffi.load("SDL_ttf") end,
  Mix = function () return ffi.load("SDL_mixer") end,

  INIT_AUDIO       = 0x00000010,
  INIT_VIDEO       = 0x00000020,
  INIT_CDROM       = 0x00000100,
  INIT_JOYSTICK    = 0x00000200,
  INIT_NOPARACHUTE = 0x00100000, --< Don't catch fatal signals
  INIT_EVENTTHREAD = 0x01000000, --< Not supported on all OS's
  INIT_EVERYTHING  = 0x0000FFFF,
  
  ANYFORMAT        = 0x10000000, --< Allow any video depth/pixel-format
  HWPALETTE        = 0x20000000, --< Surface has exclusive palette
  DOUBLEBUF        = 0x40000000, --< Set up double-buffered video mode
  FULLSCREEN       = 0x80000000, --< Surface is a full screen display
  OPENGL           = 0x00000002, --< Create an OpenGL rendering context
  OPENGLBLIT       = 0x0000000A, --< Create an OpenGL rendering context and use it for blitting
  RESIZABLE        = 0x00000010, --< This video mode may be resized
  NOFRAME          = 0x00000020, --< No window caption or edge frame

  QUERY            = -1,
  IGNORE           = 0,
  DISABLE          = 0,
  ENABLE           = 1,
}

local events = false

setmetatable(SDL, {
  __index = function (table, key)
    if key == 'addHandlerType' or key == 'userdata' or key == "handlers" then return end

    if lazy[key] then
      local value = lazy[key]
      if type(value) == "function" then
        value = value()
      end
      rawset(table, key, value)
      return value
    end
    if Emitter.prototype[key] then
      if not events then
        initEvents()
      end
      local value = Emitter.prototype[key]
      rawset(table, key, value)
      return value
    end
    return table.ffi["SDL_" .. key]
  end
})

function initEvents()
  events = true
  local event = ffi.new("SDL_Event")
  local alive = true
  local before = uv.now()
  local interval = timer.setInterval(1, function ()
    local now = uv.now()
    local delta = now - before
    before = now

    while SDL.PollEvent(event) > 0 do
      if alive then
        SDL:emit("event", event)
        SDL:emit(event.type, event)
      end
    end
    if alive then
      SDL:emit('tick', delta)
    end
  end)

  function SDL.stopEvents()
    timer.clearTimer(interval)
    alive = false
  end

end


return SDL



