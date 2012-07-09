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

#ifndef LUV_STREAM
#define LUV_STREAM

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_handle.h"

void luv_on_connection(uv_stream_t* handle, int status);
void luv_on_read(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void luv_after_shutdown(uv_shutdown_t* req, int status);
void luv_after_write(uv_write_t* req, int status);
void luv_after_connect(uv_connect_t* req, int status);

int luv_shutdown(lua_State* L);
int luv_listen (lua_State* L);
int luv_accept (lua_State* L);
int luv_read_start (lua_State* L);
int luv_read_start2(lua_State* L);
int luv_read_stop(lua_State* L);
int luv_read_stop_noref(lua_State* L);
int luv_write (lua_State* L);
int luv_write2(lua_State* L);
int luv_write_queue_size(lua_State* L);

#endif
