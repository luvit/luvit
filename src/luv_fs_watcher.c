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

#include "luv_fs_watcher.h"
#include "luv_fs.h"

void luv_on_fs_event(uv_fs_event_t* handle, const char* filename, int events, int status) {

  /* load the lua state and the userdata */
  lua_State *L = luv_handle_get_lua(handle->data);

  if (status == -1) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_fs_event", NULL);
    luv_emit_event(L, "error", 1);
  } else {

    switch (events) {
      case UV_RENAME: lua_pushstring(L, "rename"); break;
      case UV_CHANGE: lua_pushstring(L, "change"); break;
      default: lua_pushnil(L); break;
    }

    if (filename) {
      lua_pushstring(L, filename);
    } else {
      lua_pushnil(L);
    }

    luv_emit_event(L, "change", 2);

  }

}


int luv_new_fs_watcher (lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
  uv_fs_event_t* handle = luv_create_fs_watcher(L);
  uv_fs_event_init(luv_get_loop(L), handle, filename, luv_on_fs_event, 0);
  return 1;
}


