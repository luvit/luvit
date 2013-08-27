/*
 *  Copyright 2013 The Luvit Authors. All Rights Reserved.
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

#ifndef LUV_SIGNAL
#define LUV_SIGNAL

#include "lauxlib.h"
#include "lua.h"
#include "luv_handle.h"
#include "utils.h"
#include "uv.h"

int luv_new_signal(lua_State* L);

/* Wrapped functions exposed to lua */
int luv_signal_start(lua_State* L);
int luv_signal_stop(lua_State* L);

#endif

