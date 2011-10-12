#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "utils.h"

// Meant as a lua_call replace for use in async callbacks
// Uses the main loop and event source
void luv_acall(lua_State *C, int nargs, int nresults, const char* source) {
  int beforeC = lua_gettop(C);

  // Get the main thread without cheating
  lua_getfield(C, LUA_REGISTRYINDEX, "main_thread");
  lua_State* L = lua_tothread(C, -1);
  int beforeL = lua_gettop(L);
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

    if (lua_pcall(L, nargs + 2, nresults, 0)) {
      luaL_error(L, "EVERR '%s': %s", source, lua_tostring(L, -1));
    }
  }
  assert(lua_gettop(C) == beforeC - nargs - 1);

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

// Pushes a error object onto the stack
void luv_io_error(lua_State* L,
                  int errorno,
                  const char *syscall,
                  const char *msg,
                  const char *path) {

  if (!msg || !msg[0]) {
    msg = errno_message(errorno);
  }

  lua_newtable(L);
  if (path) {
    lua_pushfstring(L, "%s, %s '%s'", errno_string(errorno), msg, path);
  } else {
    lua_pushfstring(L, "%s, %s", errno_string(errorno), msg);
  }
  lua_setfield(L, -2, "message");
  lua_pushstring(L, errno_string(errorno));
  lua_setfield(L, -2, "code");
  if (path) {
    lua_pushstring(L, path);
    lua_setfield(L, -2, "path");
  }
}


// An alternative to luaL_checkudata that takes inheritance into account for polymorphism
// Make sure to not call with long type strings or strcat will overflow
void* luv_checkudata(lua_State* L, int index, const char* type) {
  // Check for table wrappers as well and replace it with the userdata it points to
  if (lua_istable (L, index)) {
    lua_getfield(L, index, "userdata");
    lua_replace(L, index);
  }
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

