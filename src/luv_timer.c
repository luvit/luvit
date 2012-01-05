#include <stdlib.h>
#include <assert.h>

#include "luv_tcp.h"
#include "utils.h"

int luv_new_timer (lua_State* L) {
  int before = lua_gettop(L);
  luv_ref_t* ref;
  uv_timer_t* handle = (uv_timer_t*)lua_newuserdata(L, sizeof(uv_timer_t));
  uv_timer_init(luv_get_loop(L), handle);

  // Set metatable for type
  luaL_getmetatable(L, "luv_timer");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // Store a reference to the userdata in the handle
  ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  assert(lua_gettop(L) == before + 1);
  // return the userdata
  return 1;
}

void luv_on_timer(uv_timer_t* handle, int status) {
  // load the lua state and the userdata
  luv_ref_t* ref = handle->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  if (status == -1) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_timer", NULL);
    luv_emit_event(L, "error", 1);
  } else {
    luv_emit_event(L, "timeout", 0);
  }
  assert(lua_gettop(L) == before);
}

int luv_timer_start(lua_State* L) {
  int before = lua_gettop(L);
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");
  int64_t timeout = luaL_checklong(L, 2);
  int64_t repeat = luaL_checklong(L, 3);
  luaL_checktype(L, 4, LUA_TFUNCTION);

  luv_register_event(L, 1, "timeout", 4);

  if (uv_timer_start(handle, luv_on_timer, timeout, repeat)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "timer_start: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}


int luv_timer_stop(lua_State* L) {
  int before = lua_gettop(L);
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");

  if (uv_timer_stop(handle)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "timer_stop: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_timer_again(lua_State* L) {
  int before = lua_gettop(L);
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");

  if (uv_timer_again(handle)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "timer_again: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_timer_set_repeat(lua_State* L) {
  int before = lua_gettop(L);
  uv_timer_t* handle = (uv_timer_t*)luv_checkudata(L, 1, "timer");
  int64_t repeat = luaL_checklong(L, 2);

  uv_timer_set_repeat(handle, repeat);

  assert(lua_gettop(L) == before);
  return 0;
}

//int64_t uv_timer_get_repeat(uv_timer_t* timer);
int luv_timer_get_repeat(lua_State* L) {
  int before = lua_gettop(L);
  uv_timer_t* timer = (uv_timer_t*)luv_checkudata(L, 1, "timer");

  int64_t repeat = uv_timer_get_repeat(timer);
  lua_pushinteger(L, repeat);

  assert(lua_gettop(L) == before + 1);
  return 1;
}

