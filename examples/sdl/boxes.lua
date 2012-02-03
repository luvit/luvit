local fs = require('fs')
local ffi = require('ffi')
local math = require('math')
local sdl = require('./sdl')
local bit = require('bit')

p("sdl", sdl)
local Rect = ffi.metatype("SDL_Rect", {})

sdl.Init(bit.bor(sdl.INIT_VIDEO,sdl.INIT_JOYSTICK))
sdl.WM_SetCaption("Luvit!", nil);
local screen = sdl.SetVideoMode(1024, 768, 0, sdl.RESIZABLE)

local joysticks = {}
sdl.JoystickEventState(sdl.ENABLE);
p("numjoysticks", sdl.NumJoysticks())
for i = 1,sdl.NumJoysticks() do
  p("Found ", ffi.string(sdl.JoystickName(i-1)));
  local joy = sdl.JoystickOpen(i-1)
  joysticks[i] = joy
end
p("Joysticks", joysticks)

local function exit()
  sdl.stopEvents()
  sdl.Quit();
  print("Thanks for Playing!");
end

sdl:on(sdl.QUIT, exit)

sdl:on(sdl.KEYDOWN, function (evt)
  p("on_keydown", evt)
  local sym = evt.key.keysym.sym
  if sym == sdl.ffi.SDLK_ESCAPE then
    exit()
  end
end)

local x = screen.w / 2
local y = screen.h / 2
local mx = 0
local my = 0

sdl:on(sdl.JOYAXISMOTION, function (evt)
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

sdl:on(sdl.JOYHATMOTION, function (evt)
  local j = evt.jhat
  p("JOYHATMOTION", {which=j.which,hat=j.hat,value=j.value})
end)

sdl:on(sdl.JOYBUTTONDOWN, function (evt)
  local j = evt.jbutton
p("sdl", sdl)

  p("JOYBUTTONDOWN", {which=j.which,button=j.button,state=j.state})
end)

sdl:on(sdl.JOYBUTTONUP, function (evt)
  local j = evt.jbutton
  p("JOYBUTTONUP", {which=j.which,button=j.button,state=j.state})
end)

local fade_color = sdl.MapRGBA(screen.format, 0, 0, 0, 1)


local spin = 2
local grow = 1.02

local w = ffi.new("int[1]", screen.w)
local h = ffi.new("int[1]", screen.h)
sdl.GFX.rotozoomSurfaceSize(screen.w, screen.h, spin, grow, w, h)
w = w[0]
h = h[0]

sdl:on(sdl.VIDEORESIZE, function (evt)
  p("ON_VIDEORESIZE", {w=evt.resize.w,h=evt.resize.h})
  local old = screen
  screen = sdl.SetVideoMode(evt.resize.w, evt.resize.h, 0, sdl.RESIZABLE)
  sdl.FreeSurface(old)
  local w = ffi.new("int[1]", screen.w)
  local h = ffi.new("int[1]", screen.h)
  sdl.GFX.rotozoomSurfaceSize(screen.w, screen.h, spin, grow, w, h)
  w = w[0]
  h = h[0]

end)

sdl:on('tick', function (delta)
  
  x = x + mx * delta
  y = y + my * delta


  
  local tmp = sdl.GFX.rotozoomSurface(screen, spin, grow, 1)
  sdl.ffi.SDL_UpperBlit(tmp, Rect((w - screen.w)/2,(h - screen.h)/2,screen.w,screen.h), screen, null)
  sdl.ffi.SDL_FreeSurface(tmp)
  local color = math.random(0x100000000)
  sdl.GFX.filledCircleColor(screen, x, y, 50, color)
  
  -- Flush the output
  sdl.Flip(screen)

end)

p("sdl", sdl)

