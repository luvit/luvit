#include <stdlib.h>
#include <assert.h>

#include "luv_misc.h"

int luv_run(lua_State* L) {
  uv_run(uv_default_loop());
  return 0;
}

int luv_ref (lua_State* L) {
  uv_ref(uv_default_loop());
  return 0;
}

int luv_unref(lua_State* L) {
  uv_unref(uv_default_loop());
  return 0;
}

int luv_update_time(lua_State* L) {
  uv_update_time(uv_default_loop());
  return 0;
}

int luv_now(lua_State* L) {
  int64_t now = uv_now(uv_default_loop());
  lua_pushinteger(L, now);
  return 1;
}

int luv_hrtime(lua_State* L) {
  int64_t now = uv_hrtime();
  lua_pushinteger(L, now);
  return 1;
}

int luv_get_free_memory(lua_State* L) {
  lua_pushnumber(L, uv_get_free_memory());
  return 1;
}

int luv_get_total_memory(lua_State* L) {
  lua_pushnumber(L, uv_get_total_memory());
  return 1;
}

int luv_loadavg(lua_State* L) {
  double avg[3];
  uv_loadavg(avg);
  lua_pushnumber(L, avg[0]);
  lua_pushnumber(L, avg[1]);
  lua_pushnumber(L, avg[2]);
  return 3;
}

