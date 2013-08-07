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

#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <limits.h> /* PATH_MAX */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "luvit.h"
#include "uv.h"
#include "utils.h"
#include "los.h"
#include "luv.h"
#include "luv_dns.h"
#include "luv_debug.h"
#ifdef USE_OPENSSL
#include "luv_tls.h"
#include "lcrypto.h"
#endif
#include "luv_zlib.h"
#include "luv_portability.h"
#include "lconstants.h"
#include "lhttp_parser.h"
#include "luv_buffer.h"
#include "lyajl.h"
#include "lenv.h"

static int luvit_exit(lua_State* L) {
  int exit_code = luaL_checkint(L, 1);
  exit(exit_code);
  return 0;
}

static int luvit_print_stderr(lua_State* L) {
  const char* line = luaL_checkstring(L, 1);
  fprintf(stderr, "%s", line);
  return 0;
}


#ifdef USE_OPENSSL

static uv_rwlock_t* locks;

static unsigned long crypto_id_cb(void) {
#ifdef _WIN32
  return (unsigned long) GetCurrentThreadId();
#else /* !_WIN32 */
  return (unsigned long) pthread_self();
#endif /* !_WIN32 */
}


static void crypto_lock_init(void) {
  int i, n;

  n = CRYPTO_num_locks();
  locks = malloc(sizeof(uv_rwlock_t) * n);

  for (i = 0; i < n; i++)
    if (uv_rwlock_init(locks + i))
      abort();
}


static void crypto_lock_cb(int mode, int n, const char* file, int line) {
  assert((mode & CRYPTO_LOCK) || (mode & CRYPTO_UNLOCK));
  assert((mode & CRYPTO_READ) || (mode & CRYPTO_WRITE));

  if (mode & CRYPTO_LOCK) {
    if (mode & CRYPTO_READ)
      uv_rwlock_rdlock(locks + n);
    else
      uv_rwlock_wrlock(locks + n);
  } else {
    if (mode & CRYPTO_READ)
      uv_rwlock_rdunlock(locks + n);
    else
      uv_rwlock_wrunlock(locks + n);
  }
}

#endif


#ifndef PATH_MAX
#define PATH_MAX 1024
#endif

static char getbuf[PATH_MAX + 1];

static int luvit_getcwd(lua_State* L) {
  uv_err_t rc;

  rc = uv_cwd(getbuf, ARRAY_SIZE(getbuf) - 1);
  if (rc.code != UV_OK) {
    return luaL_error(L, "luvit_getcwd: %s\n", strerror(errno));
  }

  getbuf[ARRAY_SIZE(getbuf) - 1] = '\0';
  lua_pushstring(L, getbuf);
  return 1;
}

#ifdef USE_OPENSSL
int luvit_init_ssl()
{
#if !defined(OPENSSL_NO_COMP)
  STACK_OF(SSL_COMP)* comp_methods;
#endif

  /* Initialize OpenSSL */
  SSL_library_init();
  OpenSSL_add_all_algorithms();
  OpenSSL_add_all_digests();
  SSL_load_error_strings();
  ERR_load_crypto_strings();

  crypto_lock_init();
  CRYPTO_set_locking_callback(crypto_lock_cb);
  CRYPTO_set_id_callback(crypto_id_cb);

  /* Turn off compression. Saves memory - do it in userland. */
#if !defined(OPENSSL_NO_COMP)
#if OPENSSL_VERSION_NUMBER < 0x00908000L
  comp_methods = SSL_COMP_get_compression_method()
#else
  comp_methods = SSL_COMP_get_compression_methods();
#endif
  sk_SSL_COMP_zero(comp_methods);
  assert(sk_SSL_COMP_num(comp_methods) == 0);
#endif

  return 0;
}
#endif

int luvit_init(lua_State *L, uv_loop_t* loop, int argc, char *argv[])
{
  int index, rc;
  ares_channel channel;
  struct ares_options options;

  memset(&options, 0, sizeof(options));

  rc = ares_library_init(ARES_LIB_INIT_ALL);
  assert(rc == ARES_SUCCESS);

  /* Pull up the preload table */
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_remove(L, -2);

#ifdef USE_OPENSSL
  /* Register tls */
  lua_pushcfunction(L, luaopen_tls);
  lua_setfield(L, -2, "_tls");
  /* Register tls */
  lua_pushcfunction(L, luaopen_crypto);
  lua_setfield(L, -2, "_crypto");
#endif
  /* Register yajl */
  lua_pushcfunction(L, luaopen_yajl);
  lua_setfield(L, -2, "yajl");
  /* Register debug */
  lua_pushcfunction(L, luaopen_debugger);
  lua_setfield(L, -2, "_debug");
  /* Register os */
  lua_pushcfunction(L, luaopen_os_binding);
  lua_setfield(L, -2, "os_binding");
  /* Register http_parser */
  lua_pushcfunction(L, luaopen_http_parser);
  lua_setfield(L, -2, "http_parser");
  /* Register luv_buffer */
  lua_pushcfunction(L, luaopen_luvbuffer);
  lua_setfield(L, -2, "cbuffer");
  /* Register uv */
  lua_pushcfunction(L, luaopen_uv_native);
  lua_setfield(L, -2, "uv_native");
  /* Register env */
  lua_pushcfunction(L, luaopen_env);
  lua_setfield(L, -2, "env");
  /* Register constants */
  lua_pushcfunction(L, luaopen_constants);
  lua_setfield(L, -2, "constants");
  /* Register zlib */
  lua_pushcfunction(L, luaopen_zlib_native);
  lua_setfield(L, -2, "zlib_native");

  /* We're done with preload, put it away */
  lua_pop(L, 1);

  /* Get argv */
  lua_createtable (L, argc, 0);
  for (index = 0; index < argc; index++) {
    lua_pushstring (L, argv[index]);
    lua_rawseti(L, -2, index);
  }
  lua_setglobal(L, "argv");

  lua_pushcfunction(L, luvit_exit);
  lua_setglobal(L, "exitProcess");

  lua_pushcfunction(L, luvit_print_stderr);
  lua_setglobal(L, "printStderr");

  lua_pushcfunction(L, luvit_getcwd);
  lua_setglobal(L, "getcwd");

  lua_pushstring(L, LUVIT_VERSION);
  lua_setglobal(L, "VERSION");

  lua_pushstring(L, UV_VERSION);
  lua_setglobal(L, "UV_VERSION");

  lua_pushstring(L, LUAJIT_VERSION);
  lua_setglobal(L, "LUAJIT_VERSION");

  lua_pushstring(L, HTTP_VERSION);
  lua_setglobal(L, "HTTP_VERSION");

  lua_pushstring(L, YAJL_VERSIONISH);
  lua_setglobal(L, "YAJL_VERSION");

  lua_pushstring(L, ZLIB_VERSION);
  lua_setglobal(L, "ZLIB_VERSION");

#ifdef USE_OPENSSL
  lua_pushstring(L, OPENSSL_VERSION_TEXT);
  lua_setglobal(L, "OPENSSL_VERSION");
#endif

  /* Hold a reference to the main thread in the registry */
  rc = lua_pushthread(L);
  assert(rc == 1);
  lua_setfield(L, LUA_REGISTRYINDEX, "main_thread");

  /* Store the loop within the registry */
  luv_set_loop(L, loop);

  /* Store the ARES Channel */
  uv_ares_init_options(luv_get_loop(L), &channel, &options, 0);
  luv_set_ares_channel(L, channel);

  return 0;
}

#ifdef _WIN32
  #define SEP "\\\\"
#else
  #define SEP "/"
#endif


int luvit_run(lua_State *L) {
  return luaL_dostring(L, "\
    local path = require('uv_native').execpath():match('^(.*)"SEP"[^"SEP"]+"SEP"[^"SEP"]+$') .. '"SEP"lib"SEP"luvit"SEP"?.lua'\
    package.path = path .. ';' .. package.path\
    assert(require('luvit'))");
}

