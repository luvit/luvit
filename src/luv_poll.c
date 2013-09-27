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

#include <stdlib.h>
#include <assert.h>

#include "luv_portability.h"
#include "luv_poll.h"
#include "utils.h"


static void _luv_on_poll_read(uv_poll_t* handle, int status, int events) {
  lua_State* L = luv_handle_get_lua(handle->data);
  luv_emit_event(L, "readable", 0);
}


int luv_new_poll(lua_State* L) {
  int fd = luaL_checkint(L, 1);
  uv_tcp_t* handle = luv_create_poll(L);
  uv_poll_init(luv_get_loop(L), handle, fd);
  return 1;
}


int luv_poll_start(lua_State* L)
{
  uv_poll_t* handle;
  int err;

  handle = (uv_poll_t*)luv_checkudata(L, 1, "poll");
  luaL_checktype(L, 2, LUA_TFUNCTION);

  luv_register_event(L, 1, "readable", 2);

  err = uv_poll_start(handle, UV_READABLE, _luv_on_poll_read);
  if (err) {
    return luaL_error(L, "lua_poll_start: %d", err);
  }

  luv_handle_ref(L, handle->data, 1);

  return 0;
}


int luv_poll_stop(lua_State* L)
{
  uv_poll_t* handle;
  int err;

  handle = (uv_poll_t*)luv_checkudata(L, 1, "poll");
  err = uv_poll_stop(handle);
  if (err) {
    return luaL_error(L, "lua_poll_stop: %d", err);
  }
  return 0;
}



