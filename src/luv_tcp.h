/*
 *  Copyright 2012 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#ifndef LUV_TCP
#define LUV_TCP

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_stream.h"

int luv_new_tcp (lua_State* L);
int luv_tcp_nodelay (lua_State* L);
int luv_tcp_keepalive (lua_State* L);
int luv_tcp_bind (lua_State* L);
int luv_tcp_bind6(lua_State* L);
int luv_tcp_getsockname(lua_State* L);
int luv_tcp_getpeername(lua_State* L);
int luv_tcp_connect(lua_State* L);
int luv_tcp_connect6(lua_State* L);

#endif
