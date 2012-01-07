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

#include "luv_process.h"
#include "utils.h"

extern char **environ;

void luv_process_on_exit(uv_process_t* handle, int exit_status, int term_signal) {
  // load the lua state and the userdata
  luv_ref_t* ref = handle->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  lua_pushinteger(L, exit_status);
  lua_pushinteger(L, term_signal);
  luv_emit_event(L, "exit", 2);

  assert(lua_gettop(L) == before);
}


// Initializes uv_process_t and starts the process.
int luv_spawn(lua_State* L) {
  int before = lua_gettop(L);
  uv_pipe_t* stdin_stream = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  uv_pipe_t* stdout_stream = (uv_pipe_t*)luv_checkudata(L, 2, "pipe");
  uv_pipe_t* stderr_stream = (uv_pipe_t*)luv_checkudata(L, 3, "pipe");
  const char* command = luaL_checkstring(L, 4);
  size_t argc;
  char** args;
  int i;
  char* cwd;
  char** env;
  uv_process_options_t options;
  uv_process_t* handle;
  int r;
  luv_ref_t* ref;

  luaL_checktype(L, 5, LUA_TTABLE); // args
  luaL_checktype(L, 6, LUA_TTABLE); // options

  // Parse the args array
  argc = lua_objlen(L, 5) + 1;
  args = malloc((argc + 1) * sizeof(char*));
  args[0] = (char*)command;
  for (i = 1; i < argc; i++) {
    lua_rawgeti(L, 5, i);
    args[i] = (char*)lua_tostring(L, -1);
    lua_pop(L, 1);
  }
  args[argc] = NULL;

  // Get the cwd
  lua_getfield(L, 6, "cwd");
  cwd = (char*)lua_tostring(L, -1);
  lua_pop(L, 1);

  // Get the env
  lua_getfield(L, 6, "env");
  env = NULL;
  if (lua_type(L, -1) == LUA_TTABLE) {
    argc = lua_objlen(L, -1);
    env = malloc((argc + 1) * sizeof(char*));
    for (i = 0; i < argc; i++) {
      lua_rawgeti(L, -1, i + 1);
      env[i] = (char*)lua_tostring(L, -1);
      lua_pop(L, 1);
    }
    env[argc] = NULL;
  }
  lua_pop(L, 1);

  options.exit_cb = luv_process_on_exit;
  options.file = command;
  options.args = args;
  
  options.env = env ? env : environ;
  options.cwd = cwd;
  options.stdin_stream = stdin_stream;
  options.stdout_stream = stdout_stream;
  options.stderr_stream = stderr_stream;

  // Create the userdata
  handle = (uv_process_t*)lua_newuserdata(L, sizeof(uv_process_t));
  r = uv_spawn(luv_get_loop(L), handle, options);
  free(args);
  if (env) free(env);
  if (r) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "spawn: %s", uv_strerror(err));
  }

  // Set metatable for type
  luaL_getmetatable(L, "luv_process");
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

// Kills the process with the specified signal. The user must still call close
// on the process.
int luv_process_kill(lua_State* L) {
  uv_process_t* handle = (uv_process_t*)luv_checkudata(L, 1, "process");
  int signum = luaL_checkint(L, 2);

  if (uv_process_kill(handle, signum)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "process_kill: %s", uv_strerror(err));
  }

  return 0;
}

