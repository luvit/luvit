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

#ifndef LUV_UTILS
#define LUV_UTILS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "ares.h"

/* C doesn't have booleans on it's own */
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE !FALSE
#endif

void luv_acall(lua_State *L, int nargs, int nresults, const char* source);

void luv_set_loop(lua_State *L, uv_loop_t *loop);
uv_loop_t* luv_get_loop(lua_State *L);

void luv_set_ares_channel(lua_State *L, ares_channel channel);
ares_channel luv_get_ares_channel(lua_State *L);
lua_State* luv_get_main_thread(lua_State *L);


void luv_push_async_error(lua_State* L, uv_err_t err, const char* source, const char* path);
void luv_push_async_error_raw(lua_State* L, const char *code, const char *msg, const char* source, const char* path);

/* An alternative to luaL_checkudata that takes inheritance into account for polymorphism
 * Make sure to not call with long type strings or strcat will overflow
 */
uv_handle_t* luv_checkudata(lua_State* L, int index, const char* type);

const char* luv_handle_type_to_string(uv_handle_type type);

/* luv handles are used as the userdata type that points to uv handles. 
 * The luv handle is considered strong when it's "active" or has non-zero 
 * reqCount.  When this happens ref will contain a luaL_ref to the userdata.
 */
typedef struct {
  uv_handle_t* handle; /* The actual uv handle. memory managed by luv */
  int refCount;        /* a count of all pending request to know strength */
  lua_State* L;        /* L and ref together form a reference to the userdata */
  int threadref;       /* if handle is created in a coroutine(not main thread), threadref is
                          the reference to the coroutine in the Lua registery. 
                          we release the reference when handle closed. 
                          if handle is created in the main thread, threadref is LUA_NOREF.
                          we must hold the coroutine, because in some cases(see issue #319) that the coroutine 
                          referenced by nothing and would collected by gc, then uv's callback touch an 
                          invalid pointer. */
  int ref;             /* ref is null when refCount is 0 meaning we're weak */
  const char* type;
} luv_handle_t;

/* Create a new luv_handle.  Input is the lua state and the size of the desired 
 * uv struct.  A new userdata is created and pushed onto the stack.  The luv
 * handle and the uv handle are interlinked.
 */
luv_handle_t* luv_handle_create(lua_State* L, size_t size, const char* type);

/* callback refs ensure that the callback function and any required data
 * survive until they are needed and don't get gc'd. Usage in stream & fs
 */
typedef struct {
  int rcb; /* callback ref */
  int rdata; /* string ref */
} luv_io_ctx_t;

void luv_io_ctx_init(luv_io_ctx_t *cbs);
void luv_io_ctx_add(lua_State* L, luv_io_ctx_t *cbs, int index);
void luv_io_ctx_callback_add(lua_State* L, luv_io_ctx_t *cbs, int index);
void luv_io_ctx_callback_rawgeti(lua_State *L, luv_io_ctx_t *cbs);
void luv_io_ctx_unref(lua_State* L, luv_io_ctx_t *cbs);

/* Convenience wrappers */
uv_udp_t* luv_create_udp(lua_State* L);
uv_fs_event_t* luv_create_fs_watcher(lua_State* L);
uv_timer_t* luv_create_timer(lua_State* L);
uv_process_t* luv_create_process(lua_State* L);
uv_tcp_t* luv_create_tcp(lua_State* L);
uv_pipe_t* luv_create_pipe(lua_State* L);
uv_tty_t* luv_create_tty(lua_State* L);

/**/
lua_State* luv_handle_get_lua(luv_handle_t* lhandle);

void luv_handle_ref(lua_State* L, luv_handle_t* lhandle, int index);
void luv_handle_unref(lua_State* L, luv_handle_t* lhandle);

#endif
