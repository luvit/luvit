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

#include "luv_pipe.h"
#include "utils.h"

int luv_new_pipe (lua_State* L) {
  int ipc = luaL_checkint(L, 1);
  uv_pipe_t* handle = luv_create_pipe(L);
  uv_pipe_init(luv_get_loop(L), handle, ipc);
  return 1;
}

int luv_pipe_open(lua_State* L) {
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  uv_file file = luaL_checkint(L, 2);

  uv_pipe_open(handle, file);

  return 0;
}

int luv_pipe_bind(lua_State* L) {
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  const char* name = luaL_checkstring(L, 2);

  if (uv_pipe_bind(handle, name)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "pipe_bind: %s", uv_strerror(err));
  }

  return 0;
}


/*int uv_pipe_connect(uv_connect_t* req, uv_pipe_t* handle,
 *    const char* name, uv_connect_cb cb);
 */
int luv_pipe_connect(lua_State* L) {
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  const char* name = luaL_checkstring(L, 2);

  uv_connect_t* req = (uv_connect_t*)malloc(sizeof(uv_connect_t));

  uv_pipe_connect(req, handle, name, luv_after_connect);

  return 0;
}


