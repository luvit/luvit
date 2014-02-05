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
#include <string.h>
#include <assert.h>


#include "luv_portability.h"
#include "luv_poll.h"
#include "utils.h"


static void _luv_on_poll(uv_poll_t* handle, int status, int events) {
  lua_State* L = luv_handle_get_lua(handle->data);
  if(events & UV_READABLE)
      luv_emit_event(L, "readable", 0);
  if(events & UV_WRITABLE)
      luv_emit_event(L, "writable", 0);
}


static int _luv_get_rw_events(const char* rw) {
  int events = 0;
       if(strcmp(rw, "r") == 0)  events |= UV_READABLE;
  else if(strcmp(rw, "w") == 0)  events |= UV_WRITABLE;
  else if(strcmp(rw, "rw") == 0) events |= UV_READABLE | UV_WRITABLE;
  else if(strcmp(rw, "wr") == 0) events |= UV_READABLE | UV_WRITABLE;
  else return -1;
  return events;
}


int luv_new_poll(lua_State* L) {
  int fd = luaL_checkint(L, 1);
  uv_poll_t* handle = luv_create_poll(L);
  uv_poll_init(luv_get_loop(L), handle, fd);
  return 1;
}


int luv_poll_start(lua_State* L)
{
  uv_poll_t* handle;
  int err;
  const char* rw;
  int events;

  handle = (uv_poll_t*)luv_checkudata(L, 1, "poll");
  rw = luaL_checkstring(L, 2);
  luaL_checktype(L, 3, LUA_TFUNCTION);
  luaL_checktype(L, 4, LUA_TFUNCTION);

  events = _luv_get_rw_events(rw);
  if(events < 0)
    return luaL_error(L, "Invalid read/write directive: %s", rw);

  if(events & UV_READABLE)
    luv_register_event(L, 1, "readable", 3);
  if(events & UV_WRITABLE)
    luv_register_event(L, 1, "writable", 4);

  err = uv_poll_start(handle, events, _luv_on_poll);
  if(err) {
    return luaL_error(L, "uv_poll_start: %d", err);
  }

  luv_handle_ref(L, handle->data, 1);

  return 0;
}


int luv_poll_stop(lua_State* L)
{
  uv_poll_t* handle;
  int err;

  handle = (uv_poll_t*)luv_checkudata(L, 1, "poll");
  err = uv_poll_stop(handle);
  if(err) {
    return luaL_error(L, "uv_poll_stop: %d", err);
  }
  return 0;
}


/* vi: ts=2 sw=2 tw=80 et
 */
