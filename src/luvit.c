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

#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <limits.h> /* PATH_MAX */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "luvit.h"
#include "uv.h"
#include "utils.h"
#include "los.h"
#include "luv.h"
#include "luv_dns.h"
#include "luv_portability.h"
#include "lconstants.h"
#include "lhttp_parser.h"
#include "lyajl.h"
#include "lenv.h"


static int luvit_exit(lua_State* L) {
  int exit_code = luaL_checkint(L, 1);
  exit(exit_code);
  return 0;
}

static int luvit_print_stderr(lua_State* L) {
  const char* line = luaL_checkstring(L, 1);
  fprintf(stderr, "%s", line);
  return 0;
}

#ifndef PATH_MAX
#define PATH_MAX 1024
#endif

static char getbuf[PATH_MAX + 1];

static int luvit_getcwd(lua_State* L) {
  uv_err_t rc;

  rc = uv_cwd(getbuf, ARRAY_SIZE(getbuf) - 1);
  if (rc.code != UV_OK) {
    return luaL_error(L, "luvit_getcwd: %s\n", strerror(errno));
  }

  getbuf[ARRAY_SIZE(getbuf) - 1] = '\0';
  lua_pushstring(L, getbuf);
  return 1;
}

int main(int argc, char *argv[])
{
  int index, rc;
  ares_channel channel;
  struct ares_options options;
  lua_State *L;
  uv_loop_t *loop;

  memset(&options, 0, sizeof(options));

  rc = ares_library_init(ARES_LIB_INIT_ALL);
  assert(rc == ARES_SUCCESS);

  L = luaL_newstate();
  if (L == NULL) {
    fprintf(stderr, "luaL_newstate has failed\n");
    return 1;
  }

  luaL_openlibs(L);

  // Pull up the preload table
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_remove(L, -2);

  // Register yajl
  lua_pushcfunction(L, luaopen_yajl);
  lua_setfield(L, -2, "yajl");
  // Register os
  lua_pushcfunction(L, luaopen_os_binding);
  lua_setfield(L, -2, "os_binding");
  // Register http_parser
  lua_pushcfunction(L, luaopen_http_parser);
  lua_setfield(L, -2, "http_parser");
  // Register uv
  lua_pushcfunction(L, luaopen_uv);
  lua_setfield(L, -2, "uv");
  // Register env
  lua_pushcfunction(L, luaopen_env);
  lua_setfield(L, -2, "env");
  // Register constants
  lua_pushcfunction(L, luaopen_constants);
  lua_setfield(L, -2, "constants");

  // We're done with preload, put it away
  lua_pop(L, 1);

  // Get argv
  lua_createtable (L, argc, 0);
  for (index = 0; index < argc; index++) {
    lua_pushstring (L, argv[index]);
    lua_rawseti(L, -2, index);
  }
  lua_setglobal(L, "argv");

  lua_pushcfunction(L, luvit_exit);
  lua_setglobal(L, "exit_process");

  lua_pushcfunction(L, luvit_print_stderr);
  lua_setglobal(L, "print_stderr");

  lua_pushcfunction(L, luvit_getcwd);
  lua_setglobal(L, "getcwd");

  lua_pushstring(L, LUVIT_VERSION);
  lua_setglobal(L, "VERSION");

  lua_pushstring(L, UV_VERSION);
  lua_setglobal(L, "UV_VERSION");
  
  lua_pushstring(L, LUAJIT_VERSION);
  lua_setglobal(L, "LUAJIT_VERSION");

  lua_pushstring(L, HTTP_VERSION);
  lua_setglobal(L, "HTTP_VERSION");

  lua_pushstring(L, YAJL_VERSIONISH);
  lua_setglobal(L, "YAJL_VERSION");

  // Hold a reference to the main thread in the registry
  assert(lua_pushthread(L) == 1);
  lua_setfield(L, LUA_REGISTRYINDEX, "main_thread");

  // Store the loop within the registry
  loop = uv_default_loop();
  luv_set_loop(L, loop);

  // Store the ARES Channel
  uv_ares_init_options(luv_get_loop(L), &channel, &options, 0);
  luv_set_ares_channel(L, &channel);

  // Run the main lua script
  if (luaL_dostring(L, "assert(require('luvit'))")) {
    printf("%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
    lua_close(L);
    return -1;
  }

  lua_close(L);
  return 0;
}
