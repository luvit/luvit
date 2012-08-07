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

#ifndef LUV_MISC
#define LUV_MISC

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"

int luv_activate_signal_handler(lua_State* L);
int luv_run(lua_State* L);
int luv_update_time(lua_State* L);
int luv_now(lua_State* L);
int luv_hrtime(lua_State* L);
int luv_get_free_memory(lua_State* L);
int luv_get_total_memory(lua_State* L);
int luv_loadavg(lua_State* L);
int luv_uptime(lua_State* L);
int luv_cpu_info(lua_State* L);
int luv_interface_addresses(lua_State* L);
int luv_execpath(lua_State* L);
int luv_get_process_title(lua_State* L);
int luv_set_process_title(lua_State* L);
int luv_handle_type(lua_State* L);
int luv_print_active_handles(lua_State* L);
int luv_print_all_handles(lua_State* L);

#endif
