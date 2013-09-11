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

#ifndef LUV_DNS
#define LUV_DNS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "ares.h"
#include "utils.h"

/* Wrapped functions exposed to lua */
int luv_dns_queryA(lua_State* L);
int luv_dns_queryAaaa(lua_State* L);
int luv_dns_queryCname(lua_State* L);
int luv_dns_queryMx(lua_State* L);
int luv_dns_queryNs(lua_State* L);
int luv_dns_queryTxt(lua_State* L);
int luv_dns_querySrv(lua_State* L);
int luv_dns_getHostByAddr(lua_State* L);
int luv_dns_getAddrInfo(lua_State* L);

int luv_dns_isIp(lua_State* L);
int luv_dns_isIpV4(lua_State* L);
int luv_dns_isIpV6(lua_State* L);

void luv_dns_initialize(lua_State *L);

#endif
