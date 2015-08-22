--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

exports.name = "luvit/serial"
exports.version = "1.0.0-0"
exports.dependencies = {
  "luvit/core@1.0.2",
  "luvit/net@1.1.1",
  "luvit/timer@1.0.0",
  "luvit/utils@1.0.0",
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/tls"
exports.description = "A node-style serial module for luvit."
exports.tags = {"luvit", "serial"}

local ffi = require 'ffi'
local arch = ffi.os .. "-" .. ffi.arch

local device = require('device')
local serial = require('./'..arch..'/serial')

local extend = function(...)
  local args = {...}
  local obj = args[1]
  for i=2, #args do
    for k,v in pairs(args[i]) do
      obj[k] = v
    end
  end
  return obj
end

--COMx[:][baud=b][parity=p][data=d][stop=s][to={on|off}][xon={on|off}][odsr={on|off}][octs={on|off}][dtr={on|off|hs}][rts={on|off|hs|tg}][idsr={on|off}]
local DEFAULT_OPTIONS = {
  baud=9600,
  data=8,
  stop=1,
  parity='N',
  to='off',
  xon='off',
  odsr='off',
  octs='off',
  dtr='off',
  rts='off',
  idsr='off',
  debug=false
}

exports.open = function(devname, ...)
  local dev,options,callback
  options = {...}
  if #options==2 then
    callback = options[2]
    options = options[1]
  elseif #options==1 then
    if type(options[1])=='function' then
      callback = options[1]
      options = nil
    else
      options=options[1]
    end
  end
  
  callback = callback or function() end
  options = extend({}, DEFAULT_OPTIONS, options or {})
  dev = serial.Serial:new(devname,options)
  dev:open(callback)
  return dev
end

exports.Device = device.Device
