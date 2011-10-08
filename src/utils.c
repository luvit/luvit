#include <stdlib.h>
#include <string.h>

#include "utils.h"

// Meant as a lua_call replace for use in async callbacks
// Uses the main loop and event source
void luv_acall(lua_State *L, int nargs, int nresults, const char* source) {
  if (lua_status(L) == LUA_YIELD) {
    // We can't lua_call into a suspended thread, bad stuff happens
    printf("DROPPING EVENT %s in thread %p\n", source, L);
    lua_pop(L, nargs + nresults + 1);
    return;
  }
  lua_call(L, nargs, nresults);
}

const char* errno_message(int errorno) {
  uv_err_t err;
  memset(&err, 0, sizeof err);
  err.code = (uv_err_code)errorno;
  return uv_strerror(err);
}

const char* errno_string(int errorno) {
  uv_err_t err;
  memset(&err, 0, sizeof err);
  err.code = (uv_err_code)errorno;
  return uv_err_name(err);
}

// An alternative to luaL_checkudata that takes inheritance into account for polymorphism
// Make sure to not call with long type strings or strcat will overflow
void* luv_checkudata(lua_State* L, int index, const char* type) {
  luaL_checktype(L, index, LUA_TUSERDATA);

  // prefix with is_ before looking up property
  char key[32];
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

