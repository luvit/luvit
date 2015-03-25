/*
 *  Copyright 2015 The Luvit Authors. All Rights Reserved.
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

static void luv_on_prepare(uv_prepare_t* handle, int status) {
  /* load the lua state and put the userdata on the stack */
  lua_State* L = luv_handle_get_lua(handle->data);
  if (status == -1) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_prepare", NULL);
    luv_emit_event(L, "error", 1);
  } else {
    luv_emit_event(L, "prepare", 0);
  }
}

int luv_new_prepare(lua_State* L) {
  uv_prepare_t* handle = luv_create_prepare(L);
  uv_prepare_init(luv_get_loop(L), handle);
  return 1;
}

int luv_prepare_start(lua_State* L) {
  uv_prepare_t* handle = (uv_prepare_t*)luv_checkudata(L, 1, "prepare");
  luaL_checktype(L, 2, LUA_TFUNCTION);
  luv_register_event(L, 1, "prepare", 2);
  if (uv_prepare_start(handle, luv_on_prepare)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "prepare_start: %s", uv_strerror(err));
  }
  luv_handle_ref(L, handle->data, 1);
  return 0;
}

int luv_prepare_stop(lua_State* L) {
  uv_prepare_t* handle = (uv_prepare_t*)luv_checkudata(L, 1, "prepare");

  if (uv_prepare_stop(handle)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "prepare_stop: %s", uv_strerror(err));
  }
  luv_handle_unref(L, handle->data);

  return 0;
}

