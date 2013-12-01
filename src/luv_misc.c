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

#include "uv.h"
#include "luv_misc.h"
#include "utils.h"

#ifndef PATH_MAX
#define PATH_MAX (8096)
#endif

#ifndef MAX_TITLE_LENGTH
#define MAX_TITLE_LENGTH (8192)
#endif

int luv_run(lua_State* L) {
  uv_run(luv_get_loop(L), UV_RUN_DEFAULT);
  return 0;
}

int luv_update_time(lua_State* L) {
  uv_update_time(luv_get_loop(L));
  return 0;
}

int luv_now(lua_State* L) {
  double now = (double)uv_now(luv_get_loop(L));
  lua_pushnumber(L, now);
  return 1;
}

int luv_hrtime(lua_State* L) {
  double now = (double) uv_hrtime() / 1000000.0;
  lua_pushnumber(L, now);
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
  int count, i;
  uv_cpu_info(&cpu_infos, &count);
  lua_newtable(L);

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

int luv_interface_addresses(lua_State* L) {
  uv_interface_address_t* interfaces;
  int count, i;
  char ip[INET6_ADDRSTRLEN];

  uv_interface_addresses(&interfaces, &count);

  lua_newtable(L);

  for (i = 0; i < count; i++) {
    const char* family;

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

int luv_get_process_title(lua_State* L) {
  char title[8192];
  uv_err_t err = uv_get_process_title(title, 8192);
  if (err.code) {
    return luaL_error(L, "uv_get_process_title: %s: %s", uv_err_name(err), uv_strerror(err));
  }
  lua_pushstring(L, title);
  return 1;
}

int luv_set_process_title(lua_State* L) {
  const char* title = luaL_checkstring(L, 1);
  uv_err_t err = uv_set_process_title(title);
  if (err.code) {
    return luaL_error(L, "uv_set_process_title: %s: %s", uv_err_name(err), uv_strerror(err));
  }
  return 0;
}


int luv_handle_type(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  uv_handle_type type = uv_guess_handle(file);
  lua_pushstring(L, luv_handle_type_to_string(type));
  return 1;
}

#ifndef NDEBUG
extern void uv_print_active_handles(uv_loop_t *loop);
extern void uv_print_all_handles(uv_loop_t *loop);

int luv_print_active_handles(lua_State* L) {
  uv_print_active_handles(luv_get_loop(L));
  return 0;
}

int luv_print_all_handles(lua_State* L) {
  uv_print_all_handles(luv_get_loop(L));
  return 0;
}
#endif
