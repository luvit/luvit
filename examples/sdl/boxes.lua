local FS = require('fs')
local Timer = require('timer')
local FFI = require('ffi')
local Debug = require('debug')
local Math = require('math')
local SDL = require('./sdl')
local Bit = require('bit')

p("SDL", SDL)
local Rect = FFI.metatype("SDL_Rect", {})

SDL.Init(Bit.bor(SDL.INIT_VIDEO,SDL.INIT_JOYSTICK))
SDL.WM_SetCaption("Luvit!", nil);
local screen = SDL.SetVideoMode(1024, 768, 0, SDL.RESIZABLE)

local joysticks = {}
SDL.JoystickEventState(SDL.ENABLE);
p("numjoysticks", SDL.NumJoysticks())
for i = 1,SDL.NumJoysticks() do
  p("Found ", FFI.string(SDL.JoystickName(i-1)));
  local joy = SDL.JoystickOpen(i-1)
  joysticks[i] = joy
end
p("Joysticks", joysticks)

local function exit()
  SDL.stop_events()
  SDL.Quit();
  print("Thanks for Playing!");
end

SDL:on(SDL.QUIT, exit)

SDL:on(SDL.KEYDOWN, function (evt)
  p("on_keydown", evt)
  local sym = evt.key.keysym.sym
  if sym == SDL.ffi.SDLK_ESCAPE then
    exit()
  end
end)

local x = screen.w / 2
local y = screen.h / 2
local mx = 0
local my = 0

SDL:on(SDL.JOYAXISMOTION, function (evt)
  local j = evt.jaxis
  p("JOYAXISMOTION", {which=j.which,axis=j.axis,value=j.value})
  -- +0 right -0 left
  -- +1 down  -1 up
  if j.axis == 0 then
    mx = j.value / 0x8000
  elseif j.axis == 1 then
    my = j.value / 0x8000
  end
end)

SDL:on(SDL.JOYHATMOTION, function (evt)
  local j = evt.jhat
  p("JOYHATMOTION", {which=j.which,hat=j.hat,value=j.value})
end)

SDL:on(SDL.JOYBUTTONDOWN, function (evt)
  local j = evt.jbutton
p("SDL", SDL)

  p("JOYBUTTONDOWN", {which=j.which,button=j.button,state=j.state})
end)

SDL:on(SDL.JOYBUTTONUP, function (evt)
  local j = evt.jbutton
  p("JOYBUTTONUP", {which=j.which,button=j.button,state=j.state})
end)

local fade_color = SDL.MapRGBA(screen.format, 0, 0, 0, 1)


local spin = 2
local grow = 1.02

local w = FFI:new("int[1]", screen.w)
local h = FFI:new("int[1]", screen.h)
SDL.GFX.rotozoomSurfaceSize(screen.w, screen.h, spin, grow, w, h)
w = w[0]
h = h[0]

SDL:on(SDL.VIDEORESIZE, function (evt)
  p("ON_VIDEORESIZE", {w=evt.resize.w,h=evt.resize.h})
  local old = screen
  screen = SDL.SetVideoMode(evt.resize.w, evt.resize.h, 0, SDL.RESIZABLE)
  SDL.FreeSurface(old)
  local w = FFI:new("int[1]", screen.w)
  local h = FFI:new("int[1]", screen.h)
  SDL.GFX.rotozoomSurfaceSize(screen.w, screen.h, spin, grow, w, h)
  w = w[0]
  h = h[0]

end)

SDL:on('tick', function (delta)
  
  x = x + mx * delta
  y = y + my * delta


  
  local tmp = SDL.GFX.rotozoomSurface(screen, spin, grow, 1)
  SDL.ffi.SDL_UpperBlit(tmp, Rect((w - screen.w)/2,(h - screen.h)/2,screen.w,screen.h), screen, null)
  SDL.ffi.SDL_FreeSurface(tmp)
  local color = Math.random(0x100000000)
  SDL.GFX.filledCircleColor(screen, x, y, 50, color)
  
  -- Flush the output
  SDL.Flip(screen)

end)

p("SDL", SDL)

