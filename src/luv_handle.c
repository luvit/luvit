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

#include "luv_handle.h"

/* Registers a callback, callback_index can't be negative */
void luv_register_event(lua_State* L, int userdata_index, const char* name, int callback_index) {
  lua_getfenv(L, userdata_index);
  lua_pushvalue(L, callback_index);
  lua_setfield(L, -2, name);
  lua_pop(L, 1);
}

/* Emit an event of the current userdata consuming nargs
 * Assumes userdata is right below args
 */
void luv_emit_event(lua_State* L, const char* name, int nargs) {
  /* Load the connection callback */
  lua_getfenv(L, -nargs - 1);
  lua_getfield(L, -1, name);
  /* remove the userdata environment */
  lua_remove(L, -2);
  /* Remove the userdata */
  lua_remove(L, -nargs - 2);

  if (lua_isfunction (L, -1) == 0) {
    lua_pop(L, 1 + nargs);
    return;
  }


  /* move the function below the args */
  lua_insert(L, -nargs - 1);
  luv_acall(L, nargs, 0, name);
}

uv_buf_t luv_on_alloc(uv_handle_t* handle, size_t suggested_size) {
  uv_buf_t buf;
  buf.base = malloc(suggested_size);
  buf.len = suggested_size;
  return buf;
}

void luv_on_close(uv_handle_t* handle) {
/*  printf("on_close\tlhandle=%p handle=%p\n", handle->data, handle);*/
  /* load the lua state and the userdata */
  luv_handle_t* lhandle = handle->data;
  lua_State *L = lhandle->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, lhandle->ref);

  luv_emit_event(L, "close", 0);

  luv_handle_unref(L, handle->data);

  if (lhandle->ref != LUA_NOREF) {
    assert(lhandle->refCount);
/*    fprintf(stderr, "WARNING: closed %s with %d extra refs lhandle=%p handle=%p\n", lhandle->type, lhandle->refCount, handle->data, handle);*/
    lhandle->refCount = 1;
    luv_handle_unref(L, handle->data);
  }
  assert(lhandle->ref == LUA_NOREF);
  /* This handle is no longer valid, clean up memory */
  lhandle->handle = 0;
  free(handle);
}

int luv_close (lua_State* L) {
  uv_handle_t* handle = luv_checkudata(L, 1, "handle");
/*  printf("close   \tlhandle=%p handle=%p\n", handle->data, handle);*/
  if (uv_is_closing(handle)) {
    fprintf(stderr, "WARNING: Handle already closing \tlhandle=%p handle=%p\n", handle->data, handle);
    return 0;
  }
  uv_close(handle, luv_on_close);
  luv_handle_ref(L, handle->data, 1);
  return 0;
}

int luv_ref(lua_State* L) {
  uv_handle_t* handle = luv_checkudata(L, 1, "handle");
  uv_ref(handle);
  return 0;
}

int luv_unref(lua_State* L) {
  uv_handle_t* handle = luv_checkudata(L, 1, "handle");
  uv_unref(handle);
  return 0;
}

int luv_set_handler(lua_State* L) {
  const char* name;
  luv_checkudata(L, 1, "handle");
  name = luaL_checkstring(L, 2);
  luaL_checktype(L, 3, LUA_TFUNCTION);

  luv_register_event(L, 1, name, 3);

  return 0;
}

