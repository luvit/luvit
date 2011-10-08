#include <stdlib.h>
#include <assert.h>

#include "luv_handle.h"

// Registers a callback, callback_index can't be negative
void luv_register_event(lua_State* L, int userdata_index, const char* name, int callback_index) {
  int before = lua_gettop(L);
  lua_getfenv(L, userdata_index);
  lua_pushvalue(L, callback_index);
  lua_setfield(L, -2, name);
  lua_pop(L, 1);
  assert(lua_gettop(L) == before);
}

// Emit an event of the current userdata consuming nargs
// Assumes userdata is right below args
void luv_emit_event(lua_State* L, const char* name, int nargs) {
  int before = lua_gettop(L);
  // Load the connection callback
  lua_getfenv(L, -nargs - 1);
  lua_getfield(L, -1, name);
  lua_remove(L, -2);
  if (lua_isfunction (L, -1) == 0) {
    //printf("missing event: on_%s\n", name);
    lua_pop(L, 1 + nargs);
    assert(lua_gettop(L) == before - nargs);
    return;
  }

  // move the function below the args
  lua_insert(L, -nargs - 1);
  luv_acall(L, nargs, 0, name);

  assert(lua_gettop(L) == before - nargs);
}

void luv_after_connect(uv_connect_t* req, int status) {
  // load the lua state and the userdata
  luv_connect_ref_t* ref = req->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  lua_pushinteger(L, status);
  luv_emit_event(L, "complete", 1);
  lua_pop(L, 1); // remove the userdata

  assert(lua_gettop(L) == before);
}

uv_buf_t luv_on_alloc(uv_handle_t* handle, size_t suggested_size) {
  uv_buf_t buf;
  buf.base = malloc(suggested_size);
  buf.len = suggested_size;
  return buf;
}

void luv_on_close(uv_handle_t* handle) {

  // load the lua state and the userdata
  luv_ref_t* ref = handle->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  luv_emit_event(L, "closed", 0);
  lua_pop(L, 1); // remove userdata

  // This handle is no longer valid, clean up memory
  luaL_unref(L, LUA_REGISTRYINDEX, ref->r);
  free(ref);

  assert(lua_gettop(L) == before);
}

int luv_close (lua_State* L) {
  int before = lua_gettop(L);
  uv_handle_t* handle = (uv_handle_t*)luv_checkudata(L, 1, "handle");
  uv_close(handle, luv_on_close);
  assert(lua_gettop(L) == before);
  return 0;
}

int luv_set_handler(lua_State* L) {
  int before = lua_gettop(L);
  luv_checkudata(L, 1, "handle");
  const char* name = luaL_checkstring(L, 2);
  luaL_checktype(L, 3, LUA_TFUNCTION);

  luv_register_event(L, 1, name, 3);

  assert(lua_gettop(L) == before);
  return 0;
}

