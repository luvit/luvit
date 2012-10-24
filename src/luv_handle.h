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

#ifndef LUV_HANDLE
#define LUV_HANDLE

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"


/* Registers a callback, callback_index can't be negative */
void luv_register_event(lua_State* L, int userdata_index, const char* name, int callback_index);

/* Emit an event of the current userdata consuming nargs
 * Assumes userdata is right below args
 */
void luv_emit_event(lua_State* L, const char* name, int nargs);

uv_buf_t luv_on_alloc(uv_handle_t* handle, size_t suggested_size);

void luv_on_close(uv_handle_t* handle);

int luv_close (lua_State* L);
int luv_set_handler(lua_State* L);

int luv_ref(lua_State* L);
int luv_unref(lua_State* L);

#endif
