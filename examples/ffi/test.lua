#!/usr/bin/env luvit

local ffi = require('ffi')
ffi.cdef[[
const char *foo();
]]
--local L = ffi.load('./lib.so')
local s = ffi.C.foo()
print("Hello", s)
