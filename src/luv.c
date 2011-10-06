#include "luv.h"
#include "uv.h"
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include "luv_fs.h"
#include "luv_handle.h"
#include "luv_udp.h"
#include "luv_stream.h"
#include "luv_tcp.h"
#include "luv_pipe.h"

////////////////////////////////////////////////////////////////////////////////
//                               Constructors                                 //
////////////////////////////////////////////////////////////////////////////////

static int luv_new_tty (lua_State* L) {
  int before = lua_gettop(L);

  //uv_tty_t* handle = (uv_tty_t*)
  lua_newuserdata(L, sizeof(uv_tty_t));

  // Set metatable for type
  luaL_getmetatable(L, "luv_pipe");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  assert(lua_gettop(L) == before + 1);

  return 1;
}

////////////////////////////////////////////////////////////////////////////////
//                              TTY Functions                                 //
////////////////////////////////////////////////////////////////////////////////

static int luv_tty_init(lua_State* L) {
  error(L, "TODO: Implement luv_tty_init");
  return 0;
}

static int luv_tty_set_mode(lua_State* L) {
  error(L, "TODO: Implement luv_tty_set_mode");
  return 0;
}

static int luv_tty_get_winsize(lua_State* L) {
  error(L, "TODO: Implement luv_tty_get_winsize");
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
//                              Loop Functions                                //
////////////////////////////////////////////////////////////////////////////////

static int luv_run (lua_State* L) {
  uv_run(uv_default_loop());
  return 0;
}

////////////////////////////////////////////////////////////////////////////////

static const luaL_reg luv_f[] = {
  // Constructors
  {"new_udp", luv_new_udp},
  {"new_tcp", luv_new_tcp},
  {"new_pipe", luv_new_pipe},
  {"new_tty", luv_new_tty},

  // Handle functions
  {"close", luv_close},
  {"set_handler", luv_set_handler},

  // UDP functions
  {"udp_init", luv_udp_init},
  {"udp_bind", luv_udp_bind},
  {"udp_bind6", luv_udp_bind6},
  {"udp_getsockname", luv_udp_getsockname},
  {"udp_send", luv_udp_send},
  {"udp_send6", luv_udp_send6},
  {"udp_recv_start", luv_udp_recv_start},
  {"udp_recv_stop", luv_udp_recv_stop},

  // Stream functions
  {"shutdown", luv_shutdown},
  {"listen", luv_listen},
  {"accept", luv_accept},
  {"read_start", luv_read_start},
  {"read_stop", luv_read_stop},
  {"write", luv_write},

  // TCP functions
  {"tcp_init", luv_tcp_init},
  {"tcp_bind", luv_tcp_bind},
  {"tcp_bind6", luv_tcp_bind6},
  {"tcp_getsockname", luv_tcp_getsockname},
  {"tcp_getpeername", luv_tcp_getpeername},
  {"tcp_connect", luv_tcp_connect},
  {"tcp_connect6", luv_tcp_connect6},

  // Pipe functions
  {"pipe_init", luv_pipe_init},
  {"pipe_open", luv_pipe_open},
  {"pipe_bind", luv_pipe_bind},
  {"pipe_connect", luv_pipe_connect},

  // TTY functions
  {"tty_init", luv_tty_init},
  {"tty_set_mode", luv_tty_set_mode},
  {"tty_get_winsize", luv_tty_get_winsize},

  // FS functions
  {"fs_open", luv_fs_open},
  {"fs_close", luv_fs_close},
  {"fs_read", luv_fs_read},
  {"fs_write", luv_fs_write},
  {"fs_unlink", luv_fs_unlink},
  {"fs_mkdir", luv_fs_mkdir},
  {"fs_rmdir", luv_fs_rmdir},

  // Loop functions
  {"run", luv_run},
  {NULL, NULL}
};

static const luaL_reg luv_handle_m[] = {
  {"close", luv_close},
  {"set_handler", luv_set_handler},
  {NULL, NULL}
};

static const luaL_reg luv_udp_m[] = {
  {"bind", luv_udp_bind},
  {"bind6", luv_udp_bind6},
  {"getsockname", luv_udp_getsockname},
  {"send", luv_udp_send},
  {"send6", luv_udp_send6},
  {"recv_start", luv_udp_recv_start},
  {"recv_stop", luv_udp_recv_stop},
  {NULL, NULL}
};

static const luaL_reg luv_stream_m[] = {
  {"shutdown", luv_shutdown},
  {"listen", luv_listen},
  {"accept", luv_accept},
  {"read_start", luv_read_start},
  {"read_stop", luv_read_stop},
  {"write", luv_write},
  {NULL, NULL}
};

static const luaL_reg luv_tcp_m[] = {
  {"init", luv_tcp_init},
  {"bind", luv_tcp_bind},
  {"bind6", luv_tcp_bind6},
  {"getsockname", luv_tcp_getsockname},
  {"getpeername", luv_tcp_getpeername},
  {"connect", luv_tcp_connect},
  {"connect6", luv_tcp_connect6},
  {NULL, NULL}
};

static const luaL_reg luv_pipe_m[] = {
  {"open", luv_pipe_open},
  {"bind", luv_pipe_bind},
  {"connect", luv_pipe_connect},
  {NULL, NULL}
};

static const luaL_reg luv_tty_m[] = {
  {"tty_set_mode", luv_tty_set_mode},
  {"tty_get_winsize", luv_tty_get_winsize},
  {NULL, NULL}
};

LUALIB_API int luaopen_uv (lua_State* L) {
  int before = lua_gettop(L);

  // metatable for handle userdata types
  // It is it's own __index table to save space
  luaL_newmetatable(L, "luv_handle");
  luaL_register(L, NULL, luv_handle_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_handle"); // Tag for polymorphic type checking
  lua_pushvalue(L, -1); // copy the metatable/table so it's still on the stack
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1);

  // Metatable for udp
  luaL_newmetatable(L, "luv_udp");
  // Create table of udp methods
  lua_newtable(L); // udp_m
  luaL_register(L, NULL, luv_udp_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_udp"); // Tag for polymorphic type checking
  // Load the parent metatable so we can inherit it's methods
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  // use method table in metatable's __index
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_udp

  // Metatable for streams
  luaL_newmetatable(L, "luv_stream");
  // Create table of stream methods
  lua_newtable(L); // stream_m
  luaL_register(L, NULL, luv_stream_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_stream"); // Tag for polymorphic type checking
  // Load the parent metatable so we can inherit it's methods
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  // use method table in metatable's __index
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_stream

  // metatable for tcp userdata
  luaL_newmetatable(L, "luv_tcp");
  // table for methods
  lua_newtable(L); // tcp_m
  luaL_register(L, NULL, luv_tcp_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_tcp"); // Tag for polymorphic type checking
  // Inherit from streams
  luaL_newmetatable(L, "luv_stream");
  lua_setmetatable(L, -2);
  // Use as __index and pop metatable
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_tcp

  // metatable for pipe userdata
  luaL_newmetatable(L, "luv_pipe");
  // table for methods
  lua_newtable(L); // pipe_m
  luaL_register(L, NULL, luv_pipe_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_pipe"); // Tag for polymorphic type checking
  // Inherit from streams
  luaL_newmetatable(L, "luv_stream");
  lua_setmetatable(L, -2);
  // Use as __index and pop metatable
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_pipe

  // metatable for tty userdata
  luaL_newmetatable(L, "luv_tty");
  // table for methods
  lua_newtable(L); // tty_m
  luaL_register(L, NULL, luv_tty_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_tty"); // Tag for polymorphic type checking
  // Inherit from streams
  luaL_newmetatable(L, "luv_stream");
  lua_setmetatable(L, -2);
  // Use as __index and pop metatable
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_tty


  // Create a new exports table with functions and constants
  lua_newtable (L);
  luaL_register(L, NULL, luv_f);
  lua_pushnumber(L, UV_VERSION_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, UV_VERSION_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");

  assert(lua_gettop(L) == before + 1);
  return 1;
}

