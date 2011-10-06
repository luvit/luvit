#!/usr/bin/env luvit

local ffi = require('ffi')
local C = ffi.C
ffi.cdef[[
int printf(const char *fmt, ...);
const char *foo();
int lws_b64_encode_string(const char *in, int in_len, const char *out, int out_size);
]]
--print(ffi.C)
--for k,v in pairs(ffi.C) do print(k, v) end
--C.printf("Hello %s!", C.foo())
local s = (' '):rep(10)
--local s = {'', '', '', '', '', '', '', '', '', ''}
C.lws_b64_encode_string('aaa', 3, s, #s)
print(s:byte())
C.printf("Hello %s!", s)
