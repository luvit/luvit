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

#include "luv_stream.h"

void luv_on_connection(uv_stream_t* handle, int status) {
  /* load the lua state and the userdata */
  lua_State* L = luv_handle_get_lua(handle->data);

  if (status == -1) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_connection", NULL);
    luv_emit_event(L, "error", 1);
  } else {
    luv_emit_event(L, "connection", 0);
  }
}

void luv_on_read(uv_stream_t* handle, ssize_t nread, uv_buf_t buf) {
  /* load the lua state and the userdata */
  lua_State* L = luv_handle_get_lua(handle->data);

  if (nread >= 0) {

    lua_pushlstring (L, buf.base, nread);
    lua_pushinteger (L, nread);
    luv_emit_event(L, "data", 2);

  } else {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    if (err.code == UV_EOF) {
      luv_emit_event(L, "end", 0);
    } else {
      luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_read", NULL);
      luv_emit_event(L, "error", 1);
    }
  }

  free(buf.base);
}

void luv_after_connect(uv_connect_t* req, int status) {
  /* load the lua state and the userdata */
  lua_State* L = luv_handle_get_lua(req->handle->data);

  if (status == -1) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "after_connect", NULL);
    luv_emit_event(L, "error", 1);
  } else {
    luv_emit_event(L, "connect", 0);
  }
  free(req);

}


void luv_after_shutdown(uv_shutdown_t* req, int status) {
  luv_io_ctx_t *cbs = req->data;

  /* load the lua state and the userdata */
  lua_State *L = luv_handle_get_lua(req->handle->data);
  lua_pop(L, 1); /* We don't need the userdata */

  /* load the request callback */
  luv_io_ctx_callback_rawgeti(L, cbs);
  luv_io_ctx_unref(L, cbs);

  if (lua_isfunction(L, -1)) {
    if (status == -1) {
      luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "after_shutdown", NULL);
      luv_acall(L, 1, 0, "after_shutdown");
    } else {
      luv_acall(L, 0, 0, "after_shutdown");
    }
  } else {
    lua_pop(L, 1);
  }

  luv_handle_unref(L, req->handle->data);
  free(req->data);
  free(req);
}

void luv_after_write(uv_write_t* req, int status) {
  luv_io_ctx_t *cbs = req->data;

  /* load the lua state and the userdata */
  lua_State *L = luv_handle_get_lua(req->handle->data);
  lua_pop(L, 1); /* We don't need the userdata */

  /* load the request callback */
  luv_io_ctx_callback_rawgeti(L, cbs);
  luv_io_ctx_unref(L, cbs);

  if (lua_isfunction(L, -1)) {
    if (status == -1) {
      luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "after_write", NULL);
      luv_acall(L, 1, 0, "after_write");
    } else {
      luv_acall(L, 0, 0, "after_write");
    }
  } else {
    lua_pop(L, 1);
  }

  luv_handle_unref(L, req->handle->data);
  free(req->data);
  free(req);
}

int luv_shutdown(lua_State* L) {
  luv_io_ctx_t *cbs;
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");

  uv_shutdown_t* req = (uv_shutdown_t*)malloc(sizeof(uv_shutdown_t));
  cbs = malloc(sizeof(luv_io_ctx_t));
  luv_io_ctx_init(cbs);

  /* Store a reference to the callback */
  luv_io_ctx_callback_add(L, cbs, 2);
  req->data = (void*)cbs;

  luv_handle_ref(L, handle->data, 1);

  uv_shutdown(req, handle, luv_after_shutdown);

  return 0;
}

int luv_listen (lua_State* L) {
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  int backlog_size;
  luaL_checktype(L, 2, LUA_TFUNCTION);
  backlog_size = luaL_optint(L, 3, 128);

  luv_register_event(L, 1, "connection", 2);

  if (uv_listen(handle, backlog_size, luv_on_connection)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    luaL_error(L, "listen: %s", uv_strerror(err));
  }

  lua_pushvalue(L, 1);
  luv_emit_event(L, "listening", 0);

  luv_handle_ref(L, handle->data, 1);

  return 0;
}

int luv_accept (lua_State* L) {
  uv_stream_t* server = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  uv_stream_t* client = (uv_stream_t*)luv_checkudata(L, 2, "stream");
  if (uv_accept(server, client)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    luaL_error(L, "accept: %s", uv_strerror(err));
  }

  return 0;
}

int luv_read_start (lua_State* L) {
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  uv_read_start(handle, luv_on_alloc, luv_on_read);
  luv_handle_ref(L, handle->data, 1);
  return 0;
}

int luv_read_start2(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_read_start2");
}

int luv_read_stop(lua_State* L) {
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  uv_read_stop(handle);
  luv_handle_unref(L, handle->data);
  return 0;
}

/* TODO: this is needed because we haven't done the libuv upgrade yet to see if
 * a handle is actually being held by the event loop. The plan is to remove this
 * function after the upgrade. */
int luv_read_stop_noref(lua_State* L) {
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  uv_read_stop(handle);
  return 0;
}

int luv_write_queue_size(lua_State* L) {
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  lua_pushnumber(L, handle->write_queue_size);
  return 1;
}

int luv_write(lua_State* L) {
  uv_buf_t buf;
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  size_t len;
  luv_io_ctx_t *cbs;
  const char* chunk = luaL_checklstring(L, 2, &len);

  uv_write_t* req = (uv_write_t*)malloc(sizeof(uv_write_t));
  cbs = malloc(sizeof(luv_io_ctx_t));
  luv_io_ctx_init(cbs);

  /* Store a reference to the callback */
  luv_io_ctx_add(L, cbs, 2);
  luv_io_ctx_callback_add(L, cbs, 3);

  req->data = (void*)cbs;

  luv_handle_ref(L, handle->data, 1);
  buf = uv_buf_init((char*)chunk, len);

  uv_write(req, handle, &buf, 1, luv_after_write);
  return 0;
}

int luv_write2(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_write2");
}


