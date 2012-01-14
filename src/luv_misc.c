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

#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include "luv_misc.h"
#include "utils.h"

#ifndef PATH_MAX
#define PATH_MAX (8096)
#endif

#ifndef _WIN32

const char *luv_signo_string(int signo) {
#define SIGNO_CASE(e)  case e: return #e;
  switch (signo) {

#ifdef SIGHUP
  SIGNO_CASE(SIGHUP);
#endif

#ifdef SIGINT
  SIGNO_CASE(SIGINT);
#endif

#ifdef SIGQUIT
  SIGNO_CASE(SIGQUIT);
#endif

#ifdef SIGILL
  SIGNO_CASE(SIGILL);
#endif

#ifdef SIGTRAP
  SIGNO_CASE(SIGTRAP);
#endif

#ifdef SIGABRT
  SIGNO_CASE(SIGABRT);
#endif

#ifdef SIGIOT
# if SIGABRT != SIGIOT
  SIGNO_CASE(SIGIOT);
# endif
#endif

#ifdef SIGBUS
  SIGNO_CASE(SIGBUS);
#endif

#ifdef SIGFPE
  SIGNO_CASE(SIGFPE);
#endif

#ifdef SIGKILL
  SIGNO_CASE(SIGKILL);
#endif

#ifdef SIGUSR1
  SIGNO_CASE(SIGUSR1);
#endif

#ifdef SIGSEGV
  SIGNO_CASE(SIGSEGV);
#endif

#ifdef SIGUSR2
  SIGNO_CASE(SIGUSR2);
#endif

#ifdef SIGPIPE
  SIGNO_CASE(SIGPIPE);
#endif

#ifdef SIGALRM
  SIGNO_CASE(SIGALRM);
#endif

#ifdef SIGTERM
  SIGNO_CASE(SIGTERM);
#endif

#ifdef SIGCHLD
  SIGNO_CASE(SIGCHLD);
#endif

#ifdef SIGSTKFLT
  SIGNO_CASE(SIGSTKFLT);
#endif


#ifdef SIGCONT
  SIGNO_CASE(SIGCONT);
#endif

#ifdef SIGSTOP
  SIGNO_CASE(SIGSTOP);
#endif

#ifdef SIGTSTP
  SIGNO_CASE(SIGTSTP);
#endif

#ifdef SIGTTIN
  SIGNO_CASE(SIGTTIN);
#endif

#ifdef SIGTTOU
  SIGNO_CASE(SIGTTOU);
#endif

#ifdef SIGURG
  SIGNO_CASE(SIGURG);
#endif

#ifdef SIGXCPU
  SIGNO_CASE(SIGXCPU);
#endif

#ifdef SIGXFSZ
  SIGNO_CASE(SIGXFSZ);
#endif

#ifdef SIGVTALRM
  SIGNO_CASE(SIGVTALRM);
#endif

#ifdef SIGPROF
  SIGNO_CASE(SIGPROF);
#endif

#ifdef SIGWINCH
  SIGNO_CASE(SIGWINCH);
#endif

#ifdef SIGIO
  SIGNO_CASE(SIGIO);
#endif

#ifdef SIGPOLL
# if SIGPOLL != SIGIO
  SIGNO_CASE(SIGPOLL);
# endif
#endif

#ifdef SIGLOST
  SIGNO_CASE(SIGLOST);
#endif

#ifdef SIGPWR
# if SIGPWR != SIGLOST
  SIGNO_CASE(SIGPWR);
# endif
#endif

#ifdef SIGSYS
  SIGNO_CASE(SIGSYS);
#endif

  }
  return "";
}


static void luv_on_signal(struct ev_loop *loop, struct ev_signal *w, int revents) {
  assert(uv_default_loop()->ev == loop);
  lua_State* L = (lua_State*)w->data;
  lua_getglobal(L, "process");
  lua_getfield(L, -1, "emit");
  lua_pushvalue(L, -2);
  lua_remove(L, -3);
  lua_pushstring(L, luv_signo_string(w->signum));
  lua_pushinteger(L, revents);
  lua_call(L, 3, 0);
}

#endif

int luv_activate_signal_handler(lua_State* L) {
#ifndef _WIN32
  int signal = luaL_checkint(L, 1);
  struct ev_signal* signal_watcher = (struct ev_signal*)malloc(sizeof(struct ev_signal));
  signal_watcher->data = L;
  ev_signal_init (signal_watcher, luv_on_signal, signal);
  struct ev_loop* loop = uv_default_loop()->ev;
  ev_signal_start (loop, signal_watcher);
#endif
  return 0;
}


int luv_run(lua_State* L) {
  uv_run(luv_get_loop(L));
  return 0;
}

int luv_ref (lua_State* L) {
  uv_ref(luv_get_loop(L));
  return 0;
}

int luv_unref(lua_State* L) {
  uv_unref(luv_get_loop(L));
  return 0;
}

int luv_update_time(lua_State* L) {
  uv_update_time(luv_get_loop(L));
  return 0;
}

int luv_now(lua_State* L) {
  int64_t now = uv_now(luv_get_loop(L));
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

int luv_uptime(lua_State* L) {
  double uptime;
  uv_uptime(&uptime);
  lua_pushnumber(L, uptime);
  return 1;
}

int luv_cpu_info(lua_State* L) {
  uv_cpu_info_t* cpu_infos;
  int count;
  uv_cpu_info(&cpu_infos, &count);
  lua_newtable(L);
  int i;
  for (i = 0; i < count; i++) {
    lua_newtable(L);
    lua_pushstring(L, (cpu_infos[i]).model);
    lua_setfield(L, -2, "model");
    lua_pushnumber(L, (cpu_infos[i]).speed);
    lua_setfield(L, -2, "speed");
    lua_newtable(L);
    lua_pushnumber(L, (cpu_infos[i]).cpu_times.user);
    lua_setfield(L, -2, "user");
    lua_pushnumber(L, (cpu_infos[i]).cpu_times.nice);
    lua_setfield(L, -2, "nice");
    lua_pushnumber(L, (cpu_infos[i]).cpu_times.sys);
    lua_setfield(L, -2, "sys");
    lua_pushnumber(L, (cpu_infos[i]).cpu_times.idle);
    lua_setfield(L, -2, "idle");
    lua_pushnumber(L, (cpu_infos[i]).cpu_times.irq);
    lua_setfield(L, -2, "irq");
    lua_setfield(L, -2, "times");
    lua_rawseti(L, -2, i + 1);
  }

  uv_free_cpu_info(cpu_infos, count);
  return 1;
}

// struct uv_interface_address_s {
//   char* name;
//   int is_internal;
//   union {
//     struct sockaddr_in address4;
//     struct sockaddr_in6 address6;
//   } address;
// };

int luv_interface_addresses(lua_State* L) {
  uv_interface_address_t* interfaces;
  int count;
  char ip[INET6_ADDRSTRLEN];

  uv_interface_addresses(&interfaces, &count);

  lua_newtable(L);
  int i;
  for (i = 0; i < count; i++) {
    lua_getfield(L, -1, interfaces[i].name);
    if (!lua_istable(L, -1)) {
      lua_pop(L, 1);
      lua_newtable(L);
      lua_pushvalue(L, -1);
      lua_setfield(L, -3, interfaces[i].name);
    }
    lua_newtable(L);
    lua_pushboolean(L, interfaces[i].is_internal);
    lua_setfield(L, -2, "internal");
    const char* family;
    if (interfaces[i].address.address4.sin_family == AF_INET) {
      uv_ip4_name(&interfaces[i].address.address4,ip, sizeof(ip));
      family = "IPv4";
    } else if (interfaces[i].address.address4.sin_family == AF_INET6) {
      uv_ip6_name(&interfaces[i].address.address6, ip, sizeof(ip));
      family = "IPv6";
    } else {
      strncpy(ip, "<unknown sa family>", INET6_ADDRSTRLEN);
      family = "<unknown>";
    }
    lua_pushstring(L, ip);
    lua_setfield(L, -2, "address");
    lua_pushstring(L, family);
    lua_setfield(L, -2, "family");
    lua_rawseti(L, -2, lua_objlen (L, -2) + 1);
    lua_pop(L, 1);
  }
  uv_free_interface_addresses(interfaces, count);
  return 1;
}

int luv_execpath(lua_State* L) {
  size_t size = 2*PATH_MAX;
  char exec_path[2*PATH_MAX];
  if (uv_exepath(exec_path, &size)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "uv_exepath: %s", uv_strerror(err));
  }
  lua_pushlstring(L, exec_path, size);
  return 1;
}

int luv_handle_type(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  uv_handle_type type = uv_guess_handle(file);
  lua_pushstring(L, luv_handle_type_to_string(type));
  return 1;
}



