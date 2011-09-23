#include "luv.h"
#include "uv.h"

static int luv_run (lua_State *L) {
  uv_run(uv_default_loop());
  return 0;
}

static int luv_new_tcp (lua_State *L) {

  uv_tcp_t* handle = (uv_tcp_t*)lua_newuserdata(L, sizeof(uv_tcp_t));
  uv_tcp_init(uv_default_loop(), handle);
  handle->data = L;

  // Set instance methods
  luaL_getmetatable(L, "luv_tcp");
  lua_setmetatable(L, -2);

  // return the userdata
  return 1;
}

static int luv_tcp_init (lua_State *L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  uv_tcp_init(uv_default_loop(), handle);
  return 0;
}

static int luv_tcp_bind (lua_State *L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);

  struct sockaddr_in address = uv_ip4_addr(host, port);
  int r = uv_tcp_bind(handle, address);

  // return r
  lua_pushnumber(L, r);
  return 1;
}

static const luaL_reg luv_tcp_m[] = {
  {"init", luv_tcp_init},
  {"bind", luv_tcp_bind},
  {NULL, NULL}
};

static const luaL_reg luv_f[] = {
  {"new_tcp", luv_new_tcp},
  {"run", luv_run},
  {NULL, NULL}
};


LUALIB_API int luaopen_uv (lua_State *L) {

  // Define the luv_tcp userdata's methods
  luaL_newmetatable(L, "luv_tcp");
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  luaL_register(L, NULL, luv_tcp_m);
  lua_pop(L, 1);

  // Create a new exports table with functions and constants
  lua_newtable (L);
  luaL_register(L, NULL, luv_f);
  lua_pushnumber(L, UV_VERSION_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, UV_VERSION_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");

  return 1;
}

