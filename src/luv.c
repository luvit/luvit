#include "luv.h"
#include "uv.h"
#include <stdlib.h>

static int luv_run (lua_State* L) {
  uv_run(uv_default_loop());
  return 0;
}

static int luv_new_tcp (lua_State* L) {

  uv_tcp_t* handle = (uv_tcp_t*)lua_newuserdata(L, sizeof(uv_tcp_t));

  // Store a reference to the userdata in the handle
  luv_ref* ref = (luv_ref*)malloc(sizeof(luv_ref));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  uv_tcp_init(uv_default_loop(), handle);

  // Set instance methods
  luaL_getmetatable(L, "luv_tcp");
  lua_setmetatable(L, -2);
  
  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // return the userdata
  return 1;
}

static int luv_tcp_init (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  uv_tcp_init(uv_default_loop(), handle);
  return 0;
}

static int luv_tcp_bind (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);

  struct sockaddr_in address = uv_ip4_addr(host, port);
  int r = uv_tcp_bind(handle, address);

  // return r
  lua_pushnumber(L, r);
  return 1;
}

void luv_tcp_on_connection(uv_stream_t* handle, int status) {
  // load the lua state and the userdata
  luv_ref* ref = handle->data;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);


  // Put the environment of the userdata on the top of the stack
  lua_getfenv(L, -1);
  // Get the on_message_begin callback and put it on the stack
  lua_getfield(L, -1, "on_connection");
  // See if it's a function
  if (lua_isfunction (L, -1) == 0) {
    // no function defined
    printf("missing: on_connection\n");
    lua_pop(L, 2);
    return;
  };
  // Push fake data argument
  lua_pushinteger(L, 42);

  if (lua_pcall(L, 1, 1, 0) != 0) {
    error(L, "error running function 'on_connection': %s", lua_tostring(L, -1));
  }
  lua_pop(L, 2); // pop returned value and the userdata env
}


static int luv_tcp_listen (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  int backlog = luaL_checkint(L, 2);
  luaL_checktype (L, 3, LUA_TFUNCTION);

  // Store the callback in the environment as "on_connection"
  lua_getfenv(L, 1);
  lua_pushvalue(L, 3); // put callback on stack
  lua_setfield(L, -2, "on_connection");
  lua_pop(L, 1); // put env away

  int r = uv_listen((uv_stream_t*)handle, backlog, luv_tcp_on_connection);
  lua_pushinteger(L, r);
  return 1;
}

static const luaL_reg luv_tcp_m[] = {
  {"init", luv_tcp_init},
  {"bind", luv_tcp_bind},
  {"listen", luv_tcp_listen},
  {NULL, NULL}
};

static const luaL_reg luv_f[] = {
  {"new_tcp", luv_new_tcp},
  {"run", luv_run},
  {NULL, NULL}
};


LUALIB_API int luaopen_uv (lua_State* L) {

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

