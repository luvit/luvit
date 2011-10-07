#include <stdlib.h>
#include <assert.h>

#include "luv_pipe.h"

int luv_new_pipe (lua_State* L) {
  int before = lua_gettop(L);
  int ipc = luaL_checkint(L, 1);

  uv_pipe_t* handle = (uv_pipe_t*)lua_newuserdata(L, sizeof(uv_pipe_t));
  uv_pipe_init(uv_default_loop(), handle, ipc);

  // Set metatable for type
  luaL_getmetatable(L, "luv_pipe");
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

int luv_pipe_open(lua_State* L) {
  int before = lua_gettop(L);
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  uv_file file = luaL_checkint(L, 2);

  uv_pipe_open(handle, file);

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_pipe_bind(lua_State* L) {
  int before = lua_gettop(L);
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  const char* name = luaL_checkstring(L, 2);

  if (uv_pipe_bind(handle, name)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "pipe_bind: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}


//int uv_pipe_connect(uv_connect_t* req, uv_pipe_t* handle,
//    const char* name, uv_connect_cb cb);
int luv_pipe_connect(lua_State* L) {
  int before = lua_gettop(L);
  uv_pipe_t* handle = (uv_pipe_t*)luv_checkudata(L, 1, "pipe");
  const char* name = luaL_checkstring(L, 2);

  luv_connect_ref_t* ref = (luv_connect_ref_t*)malloc(sizeof(luv_connect_ref_t));

  // Store a reference to the userdata
  ref->L = L;
  lua_pushvalue(L, 1);
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  // Give the connect_req access to this
  ref->connect_req.data = ref;

  if (uv_pipe_connect(&ref->connect_req, handle, name, luv_after_connect)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "pipe_connect: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}


