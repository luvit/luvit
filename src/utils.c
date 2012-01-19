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
#include <string.h>
#include <assert.h>

#include "utils.h"

// Meant as a lua_call replace for use in async callbacks
// Uses the main loop and event source
void luv_acall(lua_State *C, int nargs, int nresults, const char* source) {
  int beforeC = lua_gettop(C);
  int beforeL;
  lua_State* L;

  // Get the main thread without cheating
  lua_getfield(C, LUA_REGISTRYINDEX, "main_thread");
  L = lua_tothread(C, -1);
  beforeL = lua_gettop(L);
  lua_pop(C, 1);

  // If C is not main then move to main
  if (C != L) {
    lua_getglobal(L, "event_source");
    lua_pushstring(L, source);
    lua_xmove (C, L, nargs + 1);
    lua_call(L, nargs + 2, nresults);
    assert(lua_gettop(L) == beforeL);
  } else {

    // Wrap the call with the event_source function
    int offset = nargs + 2;
    lua_getglobal(L, "event_source");
    lua_insert(L, -offset);
    lua_pushstring(L, source);
    lua_insert(L, -offset);
    lua_call(L, nargs + 2, nresults);
  }
  assert(lua_gettop(C) == beforeC - nargs - 1);

}

// Pushes an error object onto the stack
void luv_push_async_error_raw(lua_State* L, const char *code, const char *msg, const char* source, const char* path) {

  lua_newtable(L);
  lua_getglobal(L, "error_meta");
  lua_setmetatable(L, -2);

  if (path) {
    lua_pushstring(L, path);
    lua_setfield(L, -2, "path");
    lua_pushfstring(L, "%s, %s '%s'", code, msg, path);
  } else {
    lua_pushfstring(L, "%s, %s", code, msg);
  }
  lua_setfield(L, -2, "message");

  lua_pushstring(L, code);
  lua_setfield(L, -2, "code");

  lua_pushstring(L, source);
  lua_setfield(L, -2, "source");

}

// Pushes an error object onto the stack
void luv_push_async_error(lua_State* L, uv_err_t err, const char* source, const char* path) {

  const char* code = uv_err_name(err);
  const char* msg = uv_strerror(err);
  luv_push_async_error_raw(L, code, msg, source, path);
}

// An alternative to luaL_checkudata that takes inheritance into account for polymorphism
// Make sure to not call with long type strings or strcat will overflow
void* luv_checkudata(lua_State* L, int index, const char* type) {
  char key[32];

  // Check for table wrappers as well and replace it with the userdata it points to
  if (lua_istable (L, index)) {
    lua_getfield(L, index, "userdata");
    lua_replace(L, index);
  }
  luaL_checktype(L, index, LUA_TUSERDATA);

  // prefix with is_ before looking up property
  strcpy(key, "is_");
  strcat(key, type);

  lua_getfield(L, index, key);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    luaL_argerror(L, index, key);
  };
  lua_pop(L, 1);

  return lua_touserdata(L, index);
}

const char* luv_handle_type_to_string(uv_handle_type type) {
  switch (type) {
    case UV_TCP: return "TCP";
    case UV_UDP: return "UDP";
    case UV_NAMED_PIPE: return "NAMED_PIPE";
    case UV_TTY: return "TTY";
    case UV_FILE: return "FILE";
    case UV_TIMER: return "TIMER";
    case UV_PREPARE: return "PREPARE";
    case UV_CHECK: return "CHECK";
    case UV_IDLE: return "IDLE";
    case UV_ASYNC: return "ASYNC";
    case UV_ARES_TASK: return "ARES_TASK";
    case UV_ARES_EVENT: return "ARES_EVENT";
    case UV_PROCESS: return "PROCESS";
    case UV_FS_EVENT: return "FS_EVENT";
    default: return "UNKNOWN_HANDLE";
  }
}

void luv_set_loop(lua_State *L, uv_loop_t *loop) {
  lua_pushlightuserdata(L, loop);
  lua_setfield(L, LUA_REGISTRYINDEX, "loop");
}

uv_loop_t* luv_get_loop(lua_State *L) {
  uv_loop_t *loop;
  lua_getfield(L, LUA_REGISTRYINDEX, "loop");
  loop = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return loop;
}

void luv_set_ares_channel(lua_State *L, ares_channel channel) {
  lua_pushlightuserdata(L, channel);
  lua_setfield(L, LUA_REGISTRYINDEX, "ares_channel");
}

ares_channel luv_get_ares_channel(lua_State *L) {
  ares_channel channel;
  lua_getfield(L, LUA_REGISTRYINDEX, "ares_channel");
  channel = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return channel;
}
