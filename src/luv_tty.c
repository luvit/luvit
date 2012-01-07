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

#include "luv_tty.h"
#include "utils.h"

int luv_new_tty (lua_State* L) {
  int before = lua_gettop(L);
  uv_file fd = luaL_checkint(L, 1);
  int readable = lua_toboolean(L, 2);
  luv_ref_t* ref;

  uv_tty_t* handle = (uv_tty_t*)lua_newuserdata(L, sizeof(uv_tty_t));
  uv_tty_init(luv_get_loop(L), handle, fd, readable);

  // Set metatable for type
  luaL_getmetatable(L, "luv_tty");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // Store a reference to the userdata in the handle
  ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  assert(lua_gettop(L) == before + 1);
  // return the userdata
  return 1;
}

int luv_tty_set_mode(lua_State* L) {
  int before = lua_gettop(L);
  uv_tty_t* handle = (uv_tty_t*)luv_checkudata(L, 1, "tty");
  int mode = luaL_checkint(L, 2);

  if (uv_tty_set_mode(handle, mode)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_set_mode: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_tty_reset_mode(lua_State* L) {
  uv_tty_reset_mode();
  return 0;
}

int luv_tty_get_winsize(lua_State* L) {
  int before = lua_gettop(L);
  uv_tty_t* handle = (uv_tty_t*)luv_checkudata(L, 1, "tty");

  int width, height;

  if (uv_tty_get_winsize(handle, &width, &height)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_get_winsize: %s", uv_strerror(err));
  }

  lua_pushinteger(L, width);
  lua_pushinteger(L, height);
  assert(lua_gettop(L) == before + 2);
  return 2;
}


