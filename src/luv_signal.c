#include "luv_signal.h"

static void _luv_on_signal(uv_signal_t* handle, int signum)
{
  /* load the lua state and put the userdata on the stack */
  lua_State* L = luv_handle_get_lua(handle->data);
  lua_pushnumber(L, signum);
  luv_emit_event(L, "signal", 1);
}

int luv_new_signal(lua_State* L)
{
  uv_signal_t* handle = luv_create_signal(L);
  uv_signal_init(luv_get_loop(L), handle);
  return 1;
}

/* Wrapped functions exposed to lua */
int luv_signal_start(lua_State* L)
{
  uv_signal_t* handle;
  int signum, err;

  /* Gather options */
  handle = (uv_signal_t*)luv_checkudata(L, 1, "signal");
  signum = luaL_checkint(L, 2);
  luaL_checktype(L, 3, LUA_TFUNCTION);

  /* Register the callback */
  luv_register_event(L, 1, "signal", 3);

  err = uv_signal_start(handle, _luv_on_signal, signum);
  if (err) {
    return luaL_error(L, "lua_signal_start: %d", err);
  }

  luv_handle_ref(L, handle->data, 1);

  return 0;
}

int luv_signal_stop(lua_State* L)
{
  uv_signal_t* handle;
  int err;

  handle = (uv_signal_t*)luv_checkudata(L, 1, "signal");
  err = uv_signal_stop(handle);
  if (err) {
    return luaL_error(L, "lua_signal_stop: %d", err);
  }
  return 0;
}

