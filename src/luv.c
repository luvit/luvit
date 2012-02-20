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

  /* Handle functions */
  {"close", luv_close},
  {"setHandler", luv_set_handler},

  /* UDP functions */
  {"newUdp", luv_new_udp},
  {"udpBind", luv_udp_bind},
  {"udpBind6", luv_udp_bind6},
  {"udpSetMembership", luv_udp_set_membership},
  {"udpGetsockname", luv_udp_getsockname},
  {"udpSend", luv_udp_send},
  {"udpSend6", luv_udp_send6},
  {"udpRecvStart", luv_udp_recv_start},
  {"udpRecvStop", luv_udp_recv_stop},

  /* FS Watcher functions */
  {"newFsWatcher", luv_new_fs_watcher},

  /* Timer functions */
  {"newTimer", luv_new_timer},
  {"timerStart", luv_timer_start},
  {"timerStop", luv_timer_stop},
  {"timerAgain", luv_timer_again},
  {"timerSetRepeat", luv_timer_set_repeat},
  {"timerGetRepeat", luv_timer_get_repeat},

  /* Process functions */
  {"spawn", luv_spawn},
  {"processKill", luv_process_kill},

  /* Stream functions */
  {"shutdown", luv_shutdown},
  {"listen", luv_listen},
  {"accept", luv_accept},
  {"readStart", luv_read_start},
  {"readStart2", luv_read_start2},
  {"readStop", luv_read_stop},
  {"write", luv_write},
  {"write2", luv_write2},

  /* TCP functions */
  {"newTcp", luv_new_tcp},
  {"tcpBind", luv_tcp_bind},
  {"tcpBind6", luv_tcp_bind6},
  {"tcpNodelay", luv_tcp_nodelay},
  {"tcpGetsockname", luv_tcp_getsockname},
  {"tcpGetpeername", luv_tcp_getpeername},
  {"tcpConnect", luv_tcp_connect},
  {"tcpConnect6", luv_tcp_connect6},

  /* Pipe functions */
  {"newPipe", luv_new_pipe},
  {"pipeOpen", luv_pipe_open},
  {"pipeBind", luv_pipe_bind},
  {"pipeConnect", luv_pipe_connect},

  /* TTY functions */
  {"newTty", luv_new_tty},
  {"ttySetMode", luv_tty_set_mode},
  {"ttyResetMode", luv_tty_reset_mode},
  {"ttyGetWinsize", luv_tty_get_winsize},

  /* DNS functions */
  {"dnsQueryA", luv_dns_queryA},
  {"dnsQueryAaaa", luv_dns_queryAaaa},
  {"dnsQueryCname", luv_dns_queryCname},
  {"dnsQueryMx", luv_dns_queryMx},
  {"dnsQueryNs", luv_dns_queryNs},
  {"dnsQueryTxt", luv_dns_queryTxt},
  {"dnsQuerySrv", luv_dns_querySrv},
  {"dnsGetHostByAddr", luv_dns_getHostByAddr},
  {"dnsGetAddrInfo", luv_dns_getAddrInfo},
  {"dnsIsIp", luv_dns_isIp},
  {"dnsIsIpV4", luv_dns_isIpV4},
  {"dnsIsIpV6", luv_dns_isIpV6},

  /* FS functions */
  {"fsOpen", luv_fs_open},
  {"fsClose", luv_fs_close},
  {"fsRead", luv_fs_read},
  {"fsWrite", luv_fs_write},
  {"fsUnlink", luv_fs_unlink},
  {"fsMkdir", luv_fs_mkdir},
  {"fsRmdir", luv_fs_rmdir},
  {"fsReaddir", luv_fs_readdir},
  {"fsStat", luv_fs_stat},
  {"fsFstat", luv_fs_fstat},
  {"fsRename", luv_fs_rename},
  {"fsFsync", luv_fs_fsync},
  {"fsFdatasync", luv_fs_fdatasync},
  {"fsFtruncate", luv_fs_ftruncate},
  {"fsSendfile", luv_fs_sendfile},
  {"fsChmod", luv_fs_chmod},
  {"fsUtime", luv_fs_utime},
  {"fsFutime", luv_fs_futime},
  {"fsLstat", luv_fs_lstat},
  {"fsLink", luv_fs_link},
  {"fsSymlink", luv_fs_symlink},
  {"fsReadlink", luv_fs_readlink},
  {"fsFchmod", luv_fs_fchmod},
  {"fsChown", luv_fs_chown},
  {"fsFchown", luv_fs_fchown},

  /* Misc functions */
  {"run", luv_run},
  {"ref", luv_ref},
  {"unref", luv_unref},
  {"updateTime", luv_update_time},
  {"now", luv_now},
  {"hrtime", luv_hrtime},
  {"getFreeMemory", luv_get_free_memory},
  {"getTotalMemory", luv_get_total_memory},
  {"loadavg", luv_loadavg},
  {"uptime", luv_uptime},
  {"cpuInfo", luv_cpu_info},
  {"interfaceAddresses", luv_interface_addresses},
  {"execpath", luv_execpath},
  {"handleType", luv_handle_type},
  {"activateSignalHandler", luv_activate_signal_handler},
  {NULL, NULL}
};


LUALIB_API int luaopen_uv_native (lua_State* L) {
  int before = lua_gettop(L);

  /* metatable for handle userdata types */
  /* It is it's own __index table to save space */
  luaL_newmetatable(L, "luv_handle");
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_handle"); /* Tag for polymorphic type checking */
  lua_pushvalue(L, -1); /* copy the metatable/table so it's still on the stack */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1);

  /* Metatable for udp */
  luaL_newmetatable(L, "luv_udp");
  /* Create table of udp methods */
  lua_newtable(L); /* udp_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_udp"); /* Tag for polymorphic type checking */
  /* Load the parent metatable so we can inherit it's methods */
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  /* use method table in metatable's __index */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_udp */

  /* Metatable for fs_watcher */
  luaL_newmetatable(L, "luv_fs_watcher");
  /* Create table of fs_watcher methods */
  lua_newtable(L); /* fs_watcher_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_fs_watcher"); /* Tag for polymorphic type checking */
  /* Load the parent metatable so we can inherit it's methods */
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  /* use method table in metatable's __index */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_fs_watcher */

  /* Metatable for timer */
  luaL_newmetatable(L, "luv_timer");
  /* Create table of timer methods */
  lua_newtable(L); /* timer_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_timer"); /* Tag for polymorphic type checking */
  /* Load the parent metatable so we can inherit it's methods */
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  /* use method table in metatable's __index */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_timer */

  /* Metatable for process */
  luaL_newmetatable(L, "luv_process");
  /* Create table of process methods */
  lua_newtable(L); /* process_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_process"); /* Tag for polymorphic type checking */
  /* Load the parent metatable so we can inherit it's methods */
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  /* use method table in metatable's __index */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_process */

  /* Metatable for streams */
  luaL_newmetatable(L, "luv_stream");
  /* Create table of stream methods */
  lua_newtable(L); /* stream_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_stream"); /* Tag for polymorphic type checking */
  /* Load the parent metatable so we can inherit it's methods */
  luaL_newmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);
  /* use method table in metatable's __index */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_stream */

  /* metatable for tcp userdata */
  luaL_newmetatable(L, "luv_tcp");
  /* table for methods */
  lua_newtable(L); /* tcp_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_tcp"); /* Tag for polymorphic type checking */
  /* Inherit from streams */
  luaL_newmetatable(L, "luv_stream");
  lua_setmetatable(L, -2);
  /* Use as __index and pop metatable */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_tcp */

  /* metatable for pipe userdata */
  luaL_newmetatable(L, "luv_pipe");
  /* table for methods */
  lua_newtable(L); /* pipe_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_pipe"); /* Tag for polymorphic type checking */
  /* Inherit from streams */
  luaL_newmetatable(L, "luv_stream");
  lua_setmetatable(L, -2);
  /* Use as __index and pop metatable */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_pipe */

  /* metatable for tty userdata */
  luaL_newmetatable(L, "luv_tty");
  /* table for methods */
  lua_newtable(L); /* tty_m */
  lua_pushboolean(L, TRUE);
  lua_setfield(L, -2, "is_tty"); /* Tag for polymorphic type checking */
  /* Inherit from streams */
  luaL_newmetatable(L, "luv_stream");
  lua_setmetatable(L, -2);
  /* Use as __index and pop metatable */
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1); /* we're done with luv_tty */


  /* Create a new exports table with functions and constants */
  lua_newtable (L);

  luaL_register(L, NULL, luv_f);
  lua_pushnumber(L, UV_VERSION_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, UV_VERSION_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");

  assert(lua_gettop(L) == before + 1);
  return 1;
}

