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

#include <unistd.h> // gethostname, sysconf
#include <sys/utsname.h>
#include "los.h"
#include "luv_misc.h"

static int los_hostname(lua_State* L) {
  char s[255];
  if (gethostname(s, 255) < 0) {
    luaL_error(L, "Problem getting hostname");
  }
  lua_pushstring(L, s);
  return 1;
}

static int los_type(lua_State* L) {
  struct utsname info;
  uname(&info);
  lua_pushstring(L, info.sysname);
  return 1;
}

static int los_release(lua_State* L) {
  struct utsname info;
  uname(&info);
  lua_pushstring(L, info.release);
  return 1;
}

////////////////////////////////////////////////////////////////////////////////

static const luaL_reg los_f[] = {
  {"hostname", los_hostname},
  {"loadavg", luv_loadavg},
  {"uptime", luv_uptime},
  {"totalmem", luv_get_total_memory},
  {"freemem", luv_get_free_memory},
  {"cpus", luv_cpu_info},
  {"type", los_type},
  {"release", los_release},
  {"network_interfaces", luv_interface_addresses},
  {NULL, NULL}
};

LUALIB_API int luaopen_os_binding(lua_State *L) {

  lua_newtable (L);
  luaL_register(L, NULL, los_f);

  // Return the new module
  return 1;
}

