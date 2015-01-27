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
#ifndef _luvit_lua_tls_h_
#define _luvit_lua_tls_h_

#include "lua.h"

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

#define LUVIT_OPENSSL_VERSION_NUMBER 0x100010cfL

#define TLS_SECURE_CONTEXT_HANDLE "ltls_secure_context"

#define LUVIT_DEFINE_CONSTANT(L, constant) \
  lua_pushnumber(L, constant);             \
  lua_setfield(L, -2, #constant)

/* TLS Connection class info, cross file */

/* SecureContext used to configure multiple connections */
typedef struct tls_sc_t {
  SSL_CTX *ctx;
  X509_STORE *ca_store;
} tls_sc_t;

tls_sc_t* luvit__lua_tls_sc_get(lua_State *L, int index);
int luvit__lua_tls_conn_init(lua_State *L);
int luvit__lua_tls_conn_create(lua_State *L);
int luaopen_tls(lua_State *L);

#endif
