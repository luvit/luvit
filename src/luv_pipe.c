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

#include "luv_pipe.h"
#include "utils.h"

int luv_new_pipe (lua_State* L) {
  int before = lua_gettop(L);
  int ipc = luaL_checkint(L, 1);
  luv_ref_t* ref;

  uv_pipe_t* handle = (uv_pipe_t*)lua_newuserdata(L, sizeof(uv_pipe_t));
  uv_pipe_init(luv_get_loop(L), handle, ipc);

  // Set metatable for type
  luaL_getmetatable(L, "luv_pipe");
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

int luv_pipe_open(lua_State* L) {
  int before = lua_gettop(L);
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  uv_file file = luaL_checkint(L, 2);

  uv_pipe_open(handle, file);

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_pipe_bind(lua_State* L) {
  int before = lua_gettop(L);
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  const char* name = luaL_checkstring(L, 2);

  if (uv_pipe_bind(handle, name)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "pipe_bind: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}


//int uv_pipe_connect(uv_connect_t* req, uv_pipe_t* handle,
//    const char* name, uv_connect_cb cb);
int luv_pipe_connect(lua_State* L) {
  int before = lua_gettop(L);
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  const char* name = luaL_checkstring(L, 2);

  luv_connect_ref_t* ref = (luv_connect_ref_t*)malloc(sizeof(luv_connect_ref_t));

  // Store a reference to the userdata
  ref->L = L;
  lua_pushvalue(L, 1);
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  // Give the connect_req access to this
  ref->connect_req.data = ref;

  uv_pipe_connect(&ref->connect_req, handle, name, luv_after_connect);

  assert(lua_gettop(L) == before);
  return 0;
}


