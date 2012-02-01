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

#ifndef LUV_UTILS
#define LUV_UTILS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "ares.h"

/* C doesn't have booleans on it's own */
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE !FALSE
#endif

void luv_acall(lua_State *L, int nargs, int nresults, const char* source);

void luv_set_loop(lua_State *L, uv_loop_t *loop);
uv_loop_t* luv_get_loop(lua_State *L);

void luv_set_ares_channel(lua_State *L, ares_channel channel);
ares_channel luv_get_ares_channel(lua_State *L);


void luv_push_async_error(lua_State* L, uv_err_t err, const char* source, const char* path);
void luv_push_async_error_raw(lua_State* L, const char *code, const char *msg, const char* source, const char* path);

/* An alternative to luaL_checkudata that takes inheritance into account for polymorphism
 * Make sure to not call with long type strings or strcat will overflow
 */
void* luv_checkudata(lua_State* L, int index, const char* type);

const char* luv_handle_type_to_string(uv_handle_type type);


typedef struct {
  lua_State* L;
  int r;
} luv_ref_t;

#endif
