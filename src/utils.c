#include <stdlib.h>
#include <string.h>

#include "utils.h"

// Meant as a lua_call replace for use in async callbacks
// Uses the main loop and event source
void luv_acall(lua_State *C, int nargs, int nresults, const char* source) {

  // Get the main thread without cheating
  lua_getfield(C, LUA_REGISTRYINDEX, "main_thread");
  lua_State* L = lua_tothread(C, -1);
  lua_pop(C, 1);

  // If C is not main then move to main
  if (C != L) {
    lua_getglobal(L, "event_source");
    lua_xmove (C, L, nargs + 1);
    lua_call(L, nargs + 1, nresults);
    return;
  }

  // Wrap the call with the event_source function
  int offset = nargs + 2;
  lua_getglobal(L, "event_source");
  lua_insert(L, -offset);

  if (lua_pcall(L, nargs + 1, nresults, 0)) {
    luaL_error(L, "EVERR '%s': %s", source, lua_tostring(L, -1));
  }

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

