#include <stdlib.h>
#include <assert.h>

#include "luv_tty.h"

int luv_new_tty (lua_State* L) {
  int before = lua_gettop(L);
  uv_file fd = luaL_checkint(L, 1);
  int readable = lua_toboolean(L, 2);

  uv_tty_t* handle = (uv_tty_t*)lua_newuserdata(L, sizeof(uv_tty_t));
  uv_tty_init(uv_default_loop(), handle, fd, readable);

  // Set metatable for type
  luaL_getmetatable(L, "luv_tty");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // Store a reference to the userdata in the handle
  luv_ref_t* ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  assert(lua_gettop(L) == before + 1);
  // return the userdata
  return 1;
}

int luv_tty_set_mode(lua_State* L) {
  int before = lua_gettop(L);
  uv_tty_t* handle = (uv_tty_t*)luv_checkudata(L, 1, "tty");
  int mode = luaL_checkint(L, 2);

  if (uv_tty_set_mode(handle, mode)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "tcp_set_mode: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_tty_reset_mode(lua_State* L) {
  uv_tty_reset_mode();
  return 0;
}

int luv_tty_get_winsize(lua_State* L) {
  int before = lua_gettop(L);
  uv_tty_t* handle = (uv_tty_t*)luv_checkudata(L, 1, "tty");

  int width, height;

  if (uv_tty_get_winsize(handle, &width, &height)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "tcp_get_winsize: %s", uv_strerror(err));
  }

  lua_pushinteger(L, width);
  lua_pushinteger(L, height);
  assert(lua_gettop(L) == before + 2);
  return 2;
}

