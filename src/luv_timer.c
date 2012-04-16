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

#include "luv_tcp.h"
#include "utils.h"

int luv_new_timer (lua_State* L) {
  uv_timer_t* handle = luv_create_timer(L);
  uv_timer_init(luv_get_loop(L), handle);
  return 1;
}

void luv_on_timer(uv_timer_t* handle, int status) {
  /* load the lua state and put the userdata on the stack */
  lua_State* L = luv_handle_get_lua(handle->data);

  if (status == -1) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_timer", NULL);
    luv_emit_event(L, "error", 1);
  } else {
    luv_emit_event(L, "timeout", 0);
  }

}

int luv_timer_start(lua_State* L) {
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");
  int64_t timeout = luaL_checklong(L, 2);
  int64_t repeat = luaL_checklong(L, 3);
  luaL_checktype(L, 4, LUA_TFUNCTION);

  luv_register_event(L, 1, "timeout", 4);

  if (uv_timer_start(handle, luv_on_timer, timeout, repeat)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "timer_start: %s", uv_strerror(err));
  }
  luv_handle_ref(L, handle->data, 1);

  return 0;
}


int luv_timer_stop(lua_State* L) {
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");

  if (uv_timer_stop(handle)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "timer_stop: %s", uv_strerror(err));
  }
  luv_handle_unref(L, handle->data);

  return 0;
}

int luv_timer_again(lua_State* L) {
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");

  if (uv_timer_again(handle)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "timer_again: %s", uv_strerror(err));
  }

  return 0;
}

int luv_timer_set_repeat(lua_State* L) {
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");
  int64_t repeat = luaL_checklong(L, 2);

  uv_timer_set_repeat(handle, repeat);

  return 0;
}

/*int64_t uv_timer_get_repeat(uv_timer_t* timer); */
int luv_timer_get_repeat(lua_State* L) {
  uv_timer_t* timer = (uv_timer_t*)luv_checkudata(L, 1, "timer");

  int64_t repeat = uv_timer_get_repeat(timer);
  lua_pushinteger(L, repeat);

  return 1;
}

int luv_timer_get_active(lua_State* L) {
  uv_timer_t* timer = (uv_timer_t*)luv_checkudata(L, 1, "timer");

  int active = uv_is_active((uv_handle_t*)timer);
  lua_pushboolean(L, active);

  return 1;
}

