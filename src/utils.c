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

#include "utils.h"

/* Meant as a lua_call replace for use in async callbacks
 * Uses the main loop and event source
 */
void luv_acall(lua_State *C, int nargs, int nresults, const char* source) {
  lua_State* L;

  /* Get the main thread without cheating */
  lua_getfield(C, LUA_REGISTRYINDEX, "main_thread");
  L = lua_tothread(C, -1);
  lua_pop(C, 1);

  /* If C is not main then move to main */
  if (C != L) {
    lua_getglobal(L, "eventSource");
    lua_pushstring(L, source);
    lua_xmove (C, L, nargs + 1);
    lua_call(L, nargs + 2, nresults);
  } else {

    /* Wrap the call with the eventSource function */
    int offset = nargs + 2;
    lua_getglobal(L, "eventSource");
    lua_insert(L, -offset);
    lua_pushstring(L, source);
    lua_insert(L, -offset);
    lua_call(L, nargs + 2, nresults);
  }
}

/* Pushes an error object onto the stack */
void luv_push_async_error_raw(lua_State* L, const char *code, const char *msg, const char* source, const char* path) {

  lua_newtable(L);
  lua_getglobal(L, "errorMeta");
  lua_setmetatable(L, -2);

  if (path) {
    lua_pushstring(L, path);
    lua_setfield(L, -2, "path");
    lua_pushfstring(L, "%s, %s '%s'", code, msg, path);
  } else {
    lua_pushfstring(L, "%s, %s", code, msg);
  }
  lua_setfield(L, -2, "message");

  lua_pushstring(L, code);
  lua_setfield(L, -2, "code");

  lua_pushstring(L, source);
  lua_setfield(L, -2, "source");

}

/* Pushes an error object onto the stack */
void luv_push_async_error(lua_State* L, uv_err_t err, const char* source, const char* path) {

  const char* code = uv_err_name(err);
  const char* msg = uv_strerror(err);
  luv_push_async_error_raw(L, code, msg, source, path);
}

uv_handle_t* luv_checkudata(lua_State* L, int index, const char* type) {

  /* Check for table wrappers as well and replace it with the userdata it points to */
  if (lua_istable (L, index)) {
    lua_getfield(L, index, "userdata");
    lua_replace(L, index);
  }

  luaL_checktype(L, index, LUA_TUSERDATA);

  return ((luv_handle_t*)lua_touserdata(L, index))->handle;
}

void luv_io_ctx_init(luv_io_ctx_t *cbs)
{
  cbs->rcb = LUA_NOREF;
  cbs->rdata = LUA_NOREF;
}

void luv_io_ctx_add(lua_State* L, luv_io_ctx_t *cbs, int index)
{
  int n;

  /* Create the data table if it doesn't exist */
  if (cbs->rdata == LUA_NOREF) {
    lua_newtable(L);
    cbs->rdata = luaL_ref(L, LUA_REGISTRYINDEX);
  }

  /* grab state table */
  lua_rawgeti(L, LUA_REGISTRYINDEX, cbs->rdata);

  /* find next slot in state table */
  n = luaL_getn(L, -1);
  lua_pushinteger(L, n + 1);

  /* push the state variable to be reffed */
  lua_pushvalue(L, index);

  /* ref into table and cleanup */
  lua_settable(L, -3);
  lua_pop(L, 1);
}

void luv_io_ctx_callback_add(lua_State *L, luv_io_ctx_t *cbs, int index)
{
  if (lua_isfunction(L, index)) {
    lua_pushvalue(L, index); /* Store the callback */
    cbs->rcb = luaL_ref(L, LUA_REGISTRYINDEX);
  }
}

void luv_io_ctx_callback_rawgeti(lua_State *L, luv_io_ctx_t *cbs)
{
  lua_rawgeti(L, LUA_REGISTRYINDEX, cbs->rcb);
}

void luv_io_ctx_unref(lua_State* L, luv_io_ctx_t *cbs)
{
  luaL_unref(L, LUA_REGISTRYINDEX, cbs->rdata);
  luaL_unref(L, LUA_REGISTRYINDEX, cbs->rcb);
  luv_io_ctx_init(cbs);
}

const char* luv_handle_type_to_string(uv_handle_type type) {
  switch (type) {
    case UV_TCP: return "TCP";
    case UV_UDP: return "UDP";
    case UV_NAMED_PIPE: return "NAMED_PIPE";
    case UV_TTY: return "TTY";
    case UV_FILE: return "FILE";
    case UV_TIMER: return "TIMER";
    case UV_PREPARE: return "PREPARE";
    case UV_CHECK: return "CHECK";
    case UV_IDLE: return "IDLE";
    case UV_ASYNC: return "ASYNC";
    case UV_PROCESS: return "PROCESS";
    case UV_FS_EVENT: return "FS_EVENT";
    default: return "UNKNOWN_HANDLE";
  }
}

void luv_set_loop(lua_State *L, uv_loop_t *loop) {
  lua_pushlightuserdata(L, loop);
  lua_setfield(L, LUA_REGISTRYINDEX, "loop");
}

uv_loop_t* luv_get_loop(lua_State *L) {
  uv_loop_t *loop;
  lua_getfield(L, LUA_REGISTRYINDEX, "loop");
  loop = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return loop;
}


/* Initialize a new lhandle and push the new userdata on the stack. */
luv_handle_t* luv_handle_create(lua_State* L, size_t size, const char* type) {
  lua_State* mainthread;
  /* Create the userdata and set it's metatable */
  luv_handle_t* lhandle = (luv_handle_t*)lua_newuserdata(L, sizeof(luv_handle_t));

  /* Set metatable for type */
  luaL_getmetatable(L, "luv_handle");
  lua_setmetatable(L, -2);

  /* Create a local environment for storing stuff */
  lua_newtable(L);
  lua_setfenv (L, -2);

  /* Initialize and return the lhandle */
  lhandle->handle = (uv_handle_t*)malloc(size);
  lhandle->handle->data = lhandle; /* Point back to lhandle from handle */
  lhandle->refCount = 0;
  lhandle->L = L;
 
  /* if handle create in a coroutine, we need hold the coroutine */
  mainthread = luv_get_main_thread(L);
  if (L != mainthread) { 
    lua_pushthread(L);
    lhandle->threadref = luaL_ref(L, LUA_REGISTRYINDEX);
  } else {
    lhandle->threadref = LUA_NOREF;
  }
  lhandle->ref = LUA_NOREF;
  lhandle->type = type;
  return lhandle;
}

uv_udp_t* luv_create_udp(lua_State* L) {
  return (uv_udp_t*)luv_handle_create(L, sizeof(uv_udp_t), "luv_udp")->handle;
}
uv_fs_event_t* luv_create_fs_watcher(lua_State* L) {
  return (uv_fs_event_t*)luv_handle_create(L, sizeof(uv_fs_event_t), "luv_fs_watcher")->handle;
}
uv_timer_t* luv_create_timer(lua_State* L) {
  return (uv_timer_t*)luv_handle_create(L, sizeof(uv_timer_t), "luv_timer")->handle;
}
uv_process_t* luv_create_process(lua_State* L) {
  return (uv_process_t*)luv_handle_create(L, sizeof(uv_process_t), "luv_process")->handle;
}
uv_tcp_t* luv_create_tcp(lua_State* L) {
  return (uv_tcp_t*)luv_handle_create(L, sizeof(uv_tcp_t), "luv_tcp")->handle;
}
uv_pipe_t* luv_create_pipe(lua_State* L) {
  return (uv_pipe_t*)luv_handle_create(L, sizeof(uv_pipe_t), "luv_pipe")->handle;
}
uv_tty_t* luv_create_tty(lua_State* L) {
  return (uv_tty_t*)luv_handle_create(L, sizeof(uv_tty_t), "luv_tty")->handle;
}

/* This needs to be called when an async function is started on a lhandle. */
void luv_handle_ref(lua_State* L, luv_handle_t* lhandle, int index) {
/*  printf("luv_handle_ref\t%s %p:%p\n", lhandle->type, lhandle, lhandle->handle);*/
  /* If it's inactive, store a ref. */
  if (!lhandle->refCount) {
    lua_pushvalue(L, index);
    lhandle->ref = luaL_ref(L, LUA_REGISTRYINDEX);
/*    printf("makeStrong\t%s lhandle=%p handle=%p\n", lhandle->type, lhandle, lhandle->handle);*/
  }
  lhandle->refCount++;
}

/* This needs to be called when an async callback fires on a lhandle. */
void luv_handle_unref(lua_State* L, luv_handle_t* lhandle) {
  lhandle->refCount--;
  assert(lhandle->refCount >= 0);
  /* If it's now inactive, clear the ref */
  if (!lhandle->refCount) {
    luaL_unref(L, LUA_REGISTRYINDEX, lhandle->ref);
    if (lhandle->threadref != LUA_NOREF) {
      luaL_unref(L, LUA_REGISTRYINDEX, lhandle->threadref);
      lhandle->threadref = LUA_NOREF;
    }
    lhandle->ref = LUA_NOREF;
/*    printf("makeWeak\t%s lhandle=%p handle=%p\n", lhandle->type, lhandle, lhandle->handle);*/
  }
}


/* extract the lua_State* and push the userdata on the stack */
lua_State* luv_handle_get_lua(luv_handle_t* lhandle) {
/*  printf("luv_handle_get_lua\t%s %p:%p\n", lhandle->type, lhandle, lhandle->handle);*/
  assert(lhandle->refCount); /* sanity check */
  assert(lhandle->ref != LUA_NOREF); /* the ref should be there */
  lua_rawgeti(lhandle->L, LUA_REGISTRYINDEX, lhandle->ref);
  return lhandle->L;
}


void luv_set_ares_channel(lua_State *L, ares_channel channel) {
  lua_pushlightuserdata(L, channel);
  lua_setfield(L, LUA_REGISTRYINDEX, "ares_channel");
}

ares_channel luv_get_ares_channel(lua_State *L) {
  ares_channel channel;
  lua_getfield(L, LUA_REGISTRYINDEX, "ares_channel");
  channel = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return channel;
}

lua_State* luv_get_main_thread(lua_State *L) {
  lua_State *main_thread;
  lua_getfield(L, LUA_REGISTRYINDEX, "main_thread");
  main_thread = lua_tothread(L, -1);
  lua_pop(L, 1);
  return main_thread;
}
