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

#ifndef LUV_UDP
#define LUV_UDP

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_handle.h"

int luv_new_udp (lua_State* L);
int luv_udp_bind(lua_State* L);
int luv_udp_bind6(lua_State* L);
int luv_udp_set_membership(lua_State* L);
int luv_udp_getsockname(lua_State* L);
int luv_udp_send(lua_State* L);
int luv_udp_send6(lua_State* L);
int luv_udp_recv_start(lua_State* L);
int luv_udp_recv_stop(lua_State* L);
int luv_udp_set_broadcast(lua_State* L);
int luv_udp_set_ttl(lua_State* L);
int luv_udp_set_multicast_ttl(lua_State* L);
int luv_udp_set_multicast_loopback(lua_State* L);

#endif
