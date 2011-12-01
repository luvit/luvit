#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

#include "lenv.h"

extern char **environ;

static int lenv_keys(lua_State* L) {
  int size = 0;
  while (environ[size]) size++;

  lua_createtable(L, size, 0);

  int i;
  for (i = 0; i < size; ++i) {
    const char* var = environ[i];
    const char* s = strchr(var, '=');
    const int length = s ? s - var : strlen(var);
    lua_pushlstring(L, var, length);
    lua_rawseti(L, -2, i + 1);
  }

  return 1;
}

static int lenv_get(lua_State* L) {
  const char* name = luaL_checkstring(L, 1);
  lua_pushstring(L, getenv(name));
  return 1;
}

static int lenv_put(lua_State* L) {
  const char* string = luaL_checkstring(L, 1);
  int r = putenv((char*)string);
  if (r) {
    if (errno == ENOMEM)
      return luaL_error(L, "Insufficient space to allocate new environment.");
    return luaL_error(L, "Unknown error putting new environment");
  }
  return 0;
}

static int lenv_set(lua_State* L) {
  const char* name = luaL_checkstring(L, 1);
  const char* value = luaL_checkstring(L, 2);
  int overwrite = luaL_checkint(L, 3);

#ifdef _WIN32
  if (overwrite || getenv(name) == NULL) {
    size_t name_len = strlen(name);
    size_t value_len = strlen(value);

    // Allocate space for "name=value\0"
    char* buf = malloc(name_len + 1 + value_len + 1);
    if (buf == NULL) {
      free(buf);
      return luaL_error(L, "Out of memory.");
    }

    memcpy(buf, name, name_len);
    buf[name_len] = '=';
    memcpy(buf + name_len + 1, value, value_len);
    buf[name_len + 1 + value_len] = '\0';

    if (putenv(buf)) {
      free(buf);
      if (errno == ENOMEM)
        return luaL_error(L, "Insufficient space to allocate new environment.");
      return luaL_error(L, "Unknown error updating environment.");
    }

    free(buf);
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
  size_t name_len = strlen(name);

  // Allocate space for "name=\0"
  char* buf = malloc(name_len + 2);
  if (buf == NULL) {
    free(buf);
    return luaL_error(L, "Out of memory.");
  }

  memcpy(buf, name, name_len);
  memcpy(buf + name_len, "=\0", 2);

  if (putenv(buf)) {
    free(buf);
    return luaL_error(L, "Unknown error removing environment.");
  }

  free(buf);
#else
  unsetenv(name);
#endif

  return 0;
}

////////////////////////////////////////////////////////////////////////////////


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

  // Return the new module
  return 1;
}

