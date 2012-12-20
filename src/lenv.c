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
#include <stdlib.h>
#ifdef _WIN32
#include <winsock2.h>
#include <windows.h>
#else
#include <unistd.h>
#include <errno.h>
#endif

#include "lenv.h"

#ifdef __APPLE__
#include <crt_externs.h>
/**
 * If compiled as a shared library, you do not have access to the environ symbol,
 * See man (7) environ for the fun details.
 */
char **luv_os_environ() { return *_NSGetEnviron(); }

#else

extern char **environ;

char **luv_os_environ() { return environ; }

#endif


static int lenv_keys(lua_State* L) {
  int size = 0, i;
  char **env = luv_os_environ();
  while (env[size]) size++;

  lua_createtable(L, size, 0);

  for (i = 0; i < size; ++i) {
    size_t length;
    const char* var = env[i];
    const char* s = strchr(var, '=');

    if (s != NULL) {
      length = s - var;
    }
    else {
      length =  strlen(var);
    }

    lua_pushlstring(L, var, length);
    lua_rawseti(L, -2, i + 1);
  }

  return 1;
}

static int lenv_get(lua_State* L) {
  const char* name = luaL_checkstring(L, 1);
#ifdef _WIN32
  char* s = NULL;
  DWORD size;
  size = GetEnvironmentVariable(name, NULL, 0);
  if (size) {
    DWORD ret_size;
    s = malloc(size);
    if (!s) {
      return luaL_error(L, "Malloc env get string variable failed.");
    }
    ret_size = GetEnvironmentVariable(name, s, size);
    if (ret_size == 0 || ret_size >= size) {
      free(s);
      s = NULL;
    }
  }
  lua_pushstring(L, s);
  free(s);
#else
  lua_pushstring(L, getenv(name));
#endif
  return 1;
}

static int lenv_put(lua_State* L) {
  const char* string = luaL_checkstring(L, 1);
  int r = putenv((char*)string);
#ifdef _WIN32
  if (r) {
    return luaL_error(L, "Unknown error putting new environment");
  }
#else
  if (r) {
    if (r == ENOMEM)
      return luaL_error(L, "Insufficient space to allocate new environment.");
    return luaL_error(L, "Unknown error putting new environment");
  }
#endif
  return 0;
}

static int lenv_set(lua_State* L) {
  const char* name = luaL_checkstring(L, 1);
  const char* value = luaL_checkstring(L, 2);
  int overwrite = luaL_checkint(L, 3);

#ifdef _WIN32
  if (SetEnvironmentVariable(name, value) == 0) {
    return luaL_error(L, "Failed to set environment variable");
  }
#else
  if (setenv(name, value, overwrite)) {
    return luaL_error(L, "Insufficient space in environment.");
  }
#endif

  return 0;
}

static int lenv_unset(lua_State* L) {
  const char* name = luaL_checkstring(L, 1);

#ifdef __linux__
  if (unsetenv(name)) {
    if (errno == EINVAL)
      return luaL_error(L, "EINVAL: name contained an '=' character");
    return luaL_error(L, "unsetenv: Unknown error");
  }
#elif defined(_WIN32)
  SetEnvironmentVariable(name, NULL);
#else
  unsetenv(name);
#endif

  return 0;
}

/******************************************************************************/

static const luaL_reg lenv_f[] = {
  {"keys", lenv_keys},
  {"get", lenv_get},
  {"put", lenv_put},
  {"set", lenv_set},
  {"unset", lenv_unset},
  {NULL, NULL}
};

LUALIB_API int luaopen_env(lua_State *L) {

  lua_newtable (L);
  luaL_register(L, NULL, lenv_f);

  /* Return the new module */
  return 1;
}

