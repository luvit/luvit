local FFI = require('ffi')
local Emitter = require('emitter')
local Timer = require('timer')
local FS = require('fs')
local UV = require('uv')

FFI.cdef(FS.read_file_sync(__dirname .. '/ffi_SDL.h'))

local SDL = {
}

local lazy = {
  ffi = function () return FFI.load('SDL') end,
  GFX = function () return FFI.load("SDL_gfx") end,
  TTF = function () return FFI.load("SDL_ttf") end,
  Mix = function () return FFI.load("SDL_mixer") end,

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
    if key == 'add_handler_type' or key == 'userdata' or key == "handlers" then return end

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
        init_events()
      end
      local value = Emitter.prototype[key]
      rawset(table, key, value)
      return value
    end
    return table.ffi["SDL_" .. key]
  end
})

function init_events()
  events = true
  local event = FFI.new("SDL_Event")
  local alive = true
  local before = UV.now()
  local interval = Timer.set_interval(1, function ()
    local now = UV.now()
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

  function SDL.stop_events()
    Timer.clear_timer(interval)
    alive = false
  end

end


return SDL



