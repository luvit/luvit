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

#ifndef WIN32
#include <unistd.h>
#include <sys/utsname.h>
#include <time.h>
#include <sys/time.h>
#else
#include <windows.h>
#endif
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
#ifdef WIN32
  lua_pushstring(L, "win32");
#else
  struct utsname info;
  uname(&info);
  lua_pushstring(L, info.sysname);
#endif
  return 1;
}

static int los_release(lua_State* L) {
#ifdef WIN32
  lua_pushstring(L, "Windows");
#else
  struct utsname info;
  uname(&info);
  lua_pushstring(L, info.release);
#endif
  return 1;
}

#ifdef WIN32
double los_gettime(void) {
    FILETIME ft;
    double t;
    GetSystemTimeAsFileTime(&ft);
    /* Windows file time (time since January 1, 1601 (UTC)) */
    t  = ft.dwLowDateTime/1.0e7 + ft.dwHighDateTime*(4294967296.0/1.0e7);
    /* convert to Unix Epoch time (time since January 1, 1970 (UTC)) */
    return (t - 11644473600.0);
}
#else
double los_gettime(void) {
    struct timeval v;
    gettimeofday(&v, (struct timezone *) NULL);
    /* Unix Epoch time (time since January 1, 1970 (UTC)) */
    return v.tv_sec + v.tv_usec/1.0e6;
}
#endif

static int los_time(lua_State *L)
{
    lua_pushnumber(L, los_gettime());
    return 1;
}

/******************************************************************************/


static const luaL_reg los_f[] = {
  {"hostname", los_hostname},
  {"loadavg", luv_loadavg},
  {"uptime", luv_uptime},
  {"totalmem", luv_get_total_memory},
  {"freemem", luv_get_free_memory},
  {"cpus", luv_cpu_info},
  {"type", los_type},
  {"release", los_release},
  {"networkInterfaces", luv_interface_addresses},
  {"time", los_time},
  {NULL, NULL}
};

LUALIB_API int luaopen_os_binding(lua_State *L) {

  lua_newtable (L);
  luaL_register(L, NULL, los_f);

  /* Return the new module */
  return 1;
}

