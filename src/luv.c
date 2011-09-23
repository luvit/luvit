#include "luv.h"
#include "uv.h"

static int luv_new_stream (lua_State *L) {

  uv_stream_t* stream = (uv_stream_t*)lua_newuserdata(L, sizeof(uv_stream_t));
  stream->data = L;
  luaL_getmetatable(L, "luv_stream");
  lua_setmetatable(L, -2);

  // return the userdata
  return 1;
}

static int luv_tcp_init (lua_State *L) {
  //TODO: Implement
  return 0;
}
static int luv_tcp_bind (lua_State *L) {
  //TODO: Implement
  return 0;
}
static int luv_listen (lua_State *L) {
  //TODO: Implement
  return 0;
}
static int luv_run (lua_State *L) {
  //TODO: Implement
  return 0;
}


static const luaL_reg luv_f[] = {
  {"tcp_init", luv_tcp_init},
  {"tcp_bind", luv_tcp_bind},
  {"listen", luv_listen},
  {"run", luv_run},
  {"new_stream", luv_new_stream},
  {NULL, NULL}
};

/*
** Open uv library
*/
LUALIB_API int luaopen_uv (lua_State *L) {

  // Define out userdata types
  luaL_newmetatable(L, "luv_stream");
  luaL_newmetatable(L, "luv_loop*");

  // Create a new exports table
  lua_newtable (L);
  luaL_register(L, NULL, luv_f);

  lua_pushnumber(L, UV_VERSION_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, UV_VERSION_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");

  return 1;
}


/*uv_tcp_init(uv_default_loop(), (uv_tcp_t*)&server);*/
/*  struct sockaddr_in address = uv_ip4_addr("0.0.0.0", 8080);*/
/*  int r = uv_tcp_bind((uv_tcp_t*)&server, address);*/

/*  if (r) {*/
/*    uv_err_t err = uv_last_error(uv_default_loop());*/
/*    fprintf(stderr, "bind: %s\n", uv_strerror(err));*/
/*    return -1;*/
/*  }*/

/*  r = uv_listen(&server, 128, on_connection);*/

/*  if (r) {*/
/*    uv_err_t err = uv_last_error(uv_default_loop());*/
/*    fprintf(stderr, "listen: %s\n", uv_strerror(err));*/
/*    return -1;*/
/*  }*/

/*  // Block in the main loop*/
/*  uv_run(uv_default_loop());*/


