#ifndef _luvit_lua_tls_h_
#define _luvit_lua_tls_h_

#include "lua.h"

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

#define LUVIT_OPENSSL_VERSION_NUMBER 0x1000005fL

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

#endif
