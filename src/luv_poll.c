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
#include "luv_poll.h"

int
luv_new_poll(lua_State* L) {
  int fd;
  uv_poll_t* handle;

  fd = luaL_checkint(L, 1);
  handle = luv_create_poll(L);
  (void) uv_poll_init_socket(luv_get_loop(L), handle, fd);

  return 1;
}

void
poll_cb(uv_poll_t *handle, int status, int events) {
  /* load the lua state and put the userdata on the stack */
  lua_State* L = luv_handle_get_lua(handle->data);

  if (status == -1) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_poll", NULL);
    luv_emit_event(L, "error", 1);
  } else {
    lua_pushnumber(L, events);
    luv_emit_event(L, "data", 1);
  }
}

int
luv_poll_start(lua_State* L) {
  uv_poll_t* handle = (uv_poll_t*)luv_checkudata(L, 1, "poll");
  int writable = lua_toboolean(L, 2);
  int flags = (writable) ? UV_WRITABLE : UV_READABLE;

  luaL_checktype(L, 3, LUA_TFUNCTION);
  luv_register_event(L, 1, "data", 3);
  uv_poll_start(handle, flags, poll_cb);
  luv_handle_ref(L, handle->data, 1);

  return 0;
}

int
luv_poll_stop(lua_State* L) {
  uv_poll_t* handle = (uv_poll_t*)luv_checkudata(L, 1, "poll");
  if (uv_poll_stop(handle)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "poll_stop: %s", uv_strerror(err));
  }
  return 0;
}
