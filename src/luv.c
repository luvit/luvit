/*
 *  Copyright 2012 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include "luv.h"
#include "uv.h"
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include "uv-private/ev.h"

#include "luv_fs.h"
#include "luv_dns.h"
#include "luv_handle.h"
#include "luv_udp.h"
#include "luv_fs_watcher.h"
#include "luv_timer.h"
#include "luv_process.h"
#include "luv_stream.h"
#include "luv_tcp.h"
#include "luv_pipe.h"
#include "luv_tty.h"
#include "luv_misc.h"

static const luaL_reg luv_f[] = {

  // Handle functions
  {"close", luv_close},
  {"set_handler", luv_set_handler},

  // UDP functions
  {"new_udp", luv_new_udp},
  {"udp_bind", luv_udp_bind},
  {"udp_bind6", luv_udp_bind6},
  {"udp_set_membership", luv_udp_set_membership},
  {"udp_getsockname", luv_udp_getsockname},
  {"udp_send", luv_udp_send},
  {"udp_send6", luv_udp_send6},
  {"udp_recv_start", luv_udp_recv_start},
  {"udp_recv_stop", luv_udp_recv_stop},

  // FS Watcher functions
  {"new_fs_watcher", luv_new_fs_watcher},

  // Timer functions
  {"new_timer", luv_new_timer},
  {"timer_start", luv_timer_start},
  {"timer_stop", luv_timer_stop},
  {"timer_again", luv_timer_again},
  {"timer_set_repeat", luv_timer_set_repeat},
  {"timer_get_repeat", luv_timer_get_repeat},

  // Process functions
  {"spawn", luv_spawn},
  {"process_kill", luv_process_kill},

  // Stream functions
  {"shutdown", luv_shutdown},
  {"listen", luv_listen},
  {"accept", luv_accept},
  {"read_start", luv_read_start},
  {"read_start2", luv_read_start2},
  {"read_stop", luv_read_stop},
  {"write", luv_write},
  {"write2", luv_write2},

  // TCP functions
  {"new_tcp", luv_new_tcp},
  {"tcp_bind", luv_tcp_bind},
  {"tcp_bind6", luv_tcp_bind6},
  {"tcp_nodelay", luv_tcp_nodelay},
  {"tcp_getsockname", luv_tcp_getsockname},
  {"tcp_getpeername", luv_tcp_getpeername},
  {"tcp_connect", luv_tcp_connect},
  {"tcp_connect6", luv_tcp_connect6},

  // Pipe functions
  {"new_pipe", luv_new_pipe},
  {"pipe_open", luv_pipe_open},
  {"pipe_bind", luv_pipe_bind},
  {"pipe_connect", luv_pipe_connect},

  // TTY functions
  {"new_tty", luv_new_tty},
  {"tty_set_mode", luv_tty_set_mode},
  {"tty_reset_mode", luv_tty_reset_mode},
  {"tty_get_winsize", luv_tty_get_winsize},

  // DNS functions
  {"dns_queryA", luv_dns_queryA},
  {"dns_queryAAAA", luv_dns_queryAAAA},
  {"dns_queryCNAME", luv_dns_queryCNAME},
  {"dns_queryMX", luv_dns_queryMX},
  {"dns_queryNS", luv_dns_queryNS},
  {"dns_queryTXT", luv_dns_queryTXT},
  {"dns_querySRV", luv_dns_querySRV},
  {"dns_getHostByAddr", luv_dns_getHostByAddr},
  {"dns_getAddrInfo", luv_dns_getAddrInfo},
  {"dns_isIP", luv_dns_isIP},
  {"dns_isIPv4", luv_dns_isIPv4},
  {"dns_isIPv6", luv_dns_isIPv6},

  // FS functions
  {"fs_open", luv_fs_open},
  {"fs_close", luv_fs_close},
  {"fs_read", luv_fs_read},
  {"fs_write", luv_fs_write},
  {"fs_unlink", luv_fs_unlink},
  {"fs_mkdir", luv_fs_mkdir},
  {"fs_rmdir", luv_fs_rmdir},
  {"fs_readdir", luv_fs_readdir},
  {"fs_stat", luv_fs_stat},
  {"fs_fstat", luv_fs_fstat},
  {"fs_rename", luv_fs_rename},
  {"fs_fsync", luv_fs_fsync},
  {"fs_fdatasync", luv_fs_fdatasync},
  {"fs_ftruncate", luv_fs_ftruncate},
  {"fs_sendfile", luv_fs_sendfile},
  {"fs_chmod", luv_fs_chmod},
  {"fs_utime", luv_fs_utime},
  {"fs_futime", luv_fs_futime},
  {"fs_lstat", luv_fs_lstat},
  {"fs_link", luv_fs_link},
  {"fs_symlink", luv_fs_symlink},
  {"fs_readlink", luv_fs_readlink},
  {"fs_fchmod", luv_fs_fchmod},
  {"fs_chown", luv_fs_chown},
  {"fs_fchown", luv_fs_fchown},

  // Misc functions
  {"run", luv_run},
  {"ref", luv_ref},
  {"unref", luv_unref},
  {"update_time", luv_update_time},
  {"now", luv_now},
  {"hrtime", luv_hrtime},
  {"get_free_memory", luv_get_free_memory},
  {"get_total_memory", luv_get_total_memory},
  {"loadavg", luv_loadavg},
  {"uptime", luv_uptime},
  {"cpu_info", luv_cpu_info},
  {"interface_addresses", luv_interface_addresses},
  {"execpath", luv_execpath},
  {"handle_type", luv_handle_type},
  {"activate_signal_handler", luv_activate_signal_handler},
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
  {"set_membership", luv_udp_set_membership},
  {"getsockname", luv_udp_getsockname},
  {"send", luv_udp_send},
  {"send6", luv_udp_send6},
  {"recv_start", luv_udp_recv_start},
  {"recv_stop", luv_udp_recv_stop},
  {NULL, NULL}
};

static const luaL_reg luv_fs_watcher_m[] = {
  {NULL, NULL}
};

static const luaL_reg luv_timer_m[] = {
  {"start", luv_timer_start},
  {"stop", luv_timer_stop},
  {"again", luv_timer_again},
  {"set_repeat", luv_timer_set_repeat},
  {"get_repeat", luv_timer_get_repeat},
  {NULL, NULL}
};


static const luaL_reg luv_process_m[] = {
  {"kill", luv_process_kill},
  {NULL, NULL}
};

static const luaL_reg luv_stream_m[] = {
  {"shutdown", luv_shutdown},
  {"listen", luv_listen},
  {"accept", luv_accept},
  {"read_start", luv_read_start},
  {"read_start2", luv_read_start2},
  {"read_stop", luv_read_stop},
  {"write", luv_write},
  {"write2", luv_write2},
  {NULL, NULL}
};

static const luaL_reg luv_tcp_m[] = {
  {"nodelay", luv_tcp_nodelay},
  {"keepalive", luv_tcp_keepalive},
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
  {"set_mode", luv_tty_set_mode},
  {"reset_mode", luv_tty_reset_mode},
  {"get_winsize", luv_tty_get_winsize},
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

  // Metatable for fs_watcher
  luaL_newmetatable(L, "luv_fs_watcher");
  // Create table of fs_watcher methods
  lua_newtable(L); // fs_watcher_m
  luaL_register(L, NULL, luv_fs_watcher_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_fs_watcher"); // Tag for polymorphic type checking
  // Load the parent metatable so we can inherit it's methods
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  // use method table in metatable's __index
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_fs_watcher

  // Metatable for timer
  luaL_newmetatable(L, "luv_timer");
  // Create table of timer methods
  lua_newtable(L); // timer_m
  luaL_register(L, NULL, luv_timer_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_timer"); // Tag for polymorphic type checking
  // Load the parent metatable so we can inherit it's methods
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  // use method table in metatable's __index
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_timer

  // Metatable for process
  luaL_newmetatable(L, "luv_process");
  // Create table of process methods
  lua_newtable(L); // process_m
  luaL_register(L, NULL, luv_process_m);
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_process"); // Tag for polymorphic type checking
  // Load the parent metatable so we can inherit it's methods
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  // use method table in metatable's __index
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); // we're done with luv_process

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

