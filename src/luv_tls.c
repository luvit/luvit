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

#include "luv.h"
#include "luv_tls.h"
#include "luv_tls_root_certs.h"

#include <openssl/ssl.h>


/**
 * This module is hevily inspired by Node.js' node_crypto.cc:
 *   <https://github.com/joyent/node/blob/master/src/node_crypto.cc>
 */

/**
 * We hard code a check here for the version of OpenSSL we bundle inside deps, because its
 * too easily to accidently pull in an older version of OpenSSL on random platforms with
 * weird include paths.
 */
#if !USE_SYSTEM_SSL
#if OPENSSL_VERSION_NUMBER != LUVIT_OPENSSL_VERSION_NUMBER
#error Invalid OpenSSL version number. Busted Include Paths?
#endif
#endif

#define getSC(L) luvit__lua_tls_sc_get(L, 1)

static BIO* _lua_load_bio(lua_State *L, int index) {
  const char *data;
  size_t len;
  int r = -1;
  BIO *bio;

  data = luaL_checklstring(L, index, &len);

  bio = BIO_new(BIO_s_mem());
  if (!bio) {
    return NULL;
  }

  r = BIO_write(bio, data, len);

  if (r <= 0) {
    BIO_free_all(bio);
    return NULL;
  }

  return bio;
}

static X509* _lua_load_x509(lua_State *L, int index) {
  X509 *x509;
  BIO *bio;

  bio = _lua_load_bio(L, index);
  if (!bio) {
    return NULL;
  }

  x509 = PEM_read_bio_X509(bio, NULL, NULL, NULL);
  if (!x509) {
    BIO_free_all(bio);
    return NULL;
  }

  BIO_free_all(bio);
  return x509;
}

/**
 * TLS Secure Context Methods
 */

static tls_sc_t*
newSC(lua_State *L)
{
  tls_sc_t *ctx = lua_newuserdata(L, sizeof(tls_sc_t));
  ctx->ctx = NULL;
  /* TODO: reference gloabl CA-store */
  ctx->ca_store = NULL;
  luaL_getmetatable(L, TLS_SECURE_CONTEXT_HANDLE);
  lua_setmetatable(L, -2);
  return ctx;
}

tls_sc_t*
luvit__lua_tls_sc_get(lua_State *L, int index)
{
  return luaL_checkudata(L, index, TLS_SECURE_CONTEXT_HANDLE);
}

static int
tls_sc_create(lua_State *L) {
  tls_sc_t *ctx;
  const char *method_string = lua_tostring(L, 1);
  const SSL_METHOD *method = SSLv23_method();

  if (method_string) {
    if (strcmp(method_string, "SSLv3_method") == 0) {
      method = SSLv3_method();
    } else if (strcmp(method_string, "SSLv3_server_method") == 0) {
      method = SSLv3_server_method();
    } else if (strcmp(method_string, "SSLv3_client_method") == 0) {
      method = SSLv3_client_method();
    } else if (strcmp(method_string, "SSLv23_method") == 0) {
      method = SSLv23_method();
    } else if (strcmp(method_string, "SSLv23_server_method") == 0) {
      method = SSLv23_server_method();
    } else if (strcmp(method_string, "SSLv23_client_method") == 0) {
      method = SSLv23_client_method();
    } else if (strcmp(method_string, "TLSv1_method") == 0) {
      method = TLSv1_method();
    } else if (strcmp(method_string, "TLSv1_server_method") == 0) {
      method = TLSv1_server_method();
    } else if (strcmp(method_string, "TLSv1_client_method") == 0) {
      method = TLSv1_client_method();
    } else {
      return luaL_error(L, "method not supported: %s", method_string);
    }
  }

  ctx = newSC(L);
  ctx->ctx = SSL_CTX_new(method);
  /* TODO: customize Session cache */
  SSL_CTX_set_session_cache_mode(ctx->ctx, SSL_SESS_CACHE_SERVER);

  return 1;
}

static BIO*
str2bio(const char *value, size_t length) {
  int r;
  BIO *bio;

  bio = BIO_new(BIO_s_mem());

  r = BIO_write(bio, value, length);

  if (r <= 0) {
    BIO_free_all(bio);
    return NULL;
  }

  return bio;
};

static int
tls_fatal_error_x(lua_State *L, const char *func) {
  char buf[256];
  unsigned long err = ERR_get_error();

  if (err == 0) {
    return luaL_error(L, "%s: unknown fatal error", func);
  }
  else {
    ERR_error_string(err, buf);

    ERR_clear_error();

    return luaL_error(L, "%s: %s", func, buf);
  }

  return 0;
}

#define tls_fatal_error(L) tls_fatal_error_x(L, __FUNCTION__)

static int
tls_sc_set_key(lua_State *L) {
  tls_sc_t *ctx;
  EVP_PKEY* key;
  BIO *bio;
  const char *passpharse = NULL;
  const char *keystr = NULL;
  size_t klen = 0;
  size_t plen = 0;

  ctx = getSC(L);

  keystr = luaL_checklstring(L, 2, &klen);
  passpharse = luaL_optlstring(L, 3, NULL, &plen);

  bio = str2bio(keystr, klen);
  if (!bio) {
    return luaL_error(L, "tls_sc_set_key: Failed to convert Key into a BIO");
  }

  ERR_clear_error();

  /* If the 3rd arg is NULL, the 4th arg is treated as a const char* istead of void* */
  key = PEM_read_bio_PrivateKey(bio, NULL, NULL, (void*)passpharse);

  if (!key) {
    return tls_fatal_error(L);
  }

  SSL_CTX_use_PrivateKey(ctx->ctx, key);
  EVP_PKEY_free(key);
  BIO_free_all(bio);

  return 0;
}

/**
 * Read a file that contains our certificate in "PEM" format,
 * possibly followed by a sequence of CA certificates that should be
 * sent to the peer in the Certificate message.
 *
 * Taken from OpenSSL & Node.js - editted for style.
 */
static int
SSL_CTX_use_certificate_chain(SSL_CTX *ctx, BIO *in) {
  int ret = 0;
  X509 *x = NULL;

  x = PEM_read_bio_X509_AUX(in, NULL, NULL, NULL);

  if (x == NULL) {
    SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE_CHAIN_FILE, ERR_R_PEM_LIB);
    goto end;
  }

  ret = SSL_CTX_use_certificate(ctx, x);

  if (ERR_peek_error() != 0) {
    /* Key/certificate mismatch doesn't imply ret==0 ... */
    ret = 0;
  }

  if (ret) {
    /* If we could set up our certificate, now proceed to the CA certificates. */
    X509 *ca;
    int r;
    unsigned long err;

    if (ctx->extra_certs != NULL) {
      sk_X509_pop_free(ctx->extra_certs, X509_free);
      ctx->extra_certs = NULL;
    }

    while ((ca = PEM_read_bio_X509(in, NULL, NULL, NULL))) {
      r = SSL_CTX_add_extra_chain_cert(ctx, ca);

      if (!r) {
        X509_free(ca);
        ret = 0;
        goto end;
      }
      /* Note that we must not free r if it was successfully
       * added to the chain (while we must free the main
       * certificate, since its reference count is increased
       * by SSL_CTX_use_certificate). */
    }

    /* When the while loop ends, it's usually just EOF. */
    err = ERR_peek_last_error();
    if (ERR_GET_LIB(err) == ERR_LIB_PEM &&
        ERR_GET_REASON(err) == PEM_R_NO_START_LINE) {
      ERR_clear_error();
    } else  {
      /* some real error */
      ret = 0;
    }
  }

end:
  if (x != NULL) {
    X509_free(x);
  }
  return ret;
}

/**
 * Read from a BIO, adding to the x509 store.
 */
static int
X509_STORE_load_bio(X509_STORE *ca_store, BIO *in) {
  int ret = 1;
  X509 *ca;
  int r;
  int found = 0;
  unsigned long err;

  while ((ca = PEM_read_bio_X509(in, NULL, NULL, NULL))) {

    r = X509_STORE_add_cert(ca_store, ca);

    if (r == 0) {
      X509_free(ca);
      ret = 0;
      break;
    }

    found++;

    /**
     * The x509 cert object is reference counted by OpenSSL, so the STORE
     * keeps it alive after its been added.
     */
    X509_free(ca);
  }

  /* When the while loop ends, it's usually just EOF. */
  err = ERR_peek_last_error();
  if (found != 0 &&
      ERR_GET_LIB(err) == ERR_LIB_PEM &&
      ERR_GET_REASON(err) == PEM_R_NO_START_LINE) {
    ERR_clear_error();
  } else  {
    /* some real error */
    ret = 0;
  }

  return ret;
}

static int
tls_sc_set_cert(lua_State *L) {
  tls_sc_t *ctx;
  BIO *bio;
  const char *keystr = NULL;
  size_t klen = 0;
  int rv;

  ctx = getSC(L);

  keystr = luaL_checklstring(L, 2, &klen);

  bio = str2bio(keystr, klen);
  if (!bio) {
    return luaL_error(L, "tls_sc_set_key: Failed to convert Cert into a BIO");
  }

  ERR_clear_error();

  rv = SSL_CTX_use_certificate_chain(ctx->ctx, bio);

  if (!rv) {
    BIO_free_all(bio);
    return tls_fatal_error(L);
  }

  BIO_free_all(bio);

  return 0;
}

static int
tls_sc_add_trusted_cert(lua_State *L) {
  tls_sc_t *ctx;
  BIO *bio;
  const char *certstr = NULL;
  size_t clen = 0;
  int rv;

  ctx = getSC(L);

  if (ctx->ca_store == NULL) {
    /* TODO: better handling of global CA cert list */
    ctx->ca_store = X509_STORE_new();
    SSL_CTX_set_cert_store(ctx->ctx, ctx->ca_store);
  }

  certstr = luaL_checklstring(L, 2, &clen);

  bio = str2bio(certstr, clen);

  if (!bio) {
    return luaL_error(L, "tls_sc_add_trusted_cert: Failed to convert Cert into a BIO");
  }

  ERR_clear_error();

  rv = X509_STORE_load_bio(ctx->ca_store, bio);

  if (!rv) {
    BIO_free_all(bio);
    return tls_fatal_error(L);
  }

  BIO_free_all(bio);

  return 0;
}

static int
tls_sc_set_ciphers(lua_State *L) {
  tls_sc_t *ctx;
  const char *cipherstr = NULL;
  int rv;

  ctx = getSC(L);

  cipherstr = luaL_checkstring(L, 2);

  ERR_clear_error();

  rv = SSL_CTX_set_cipher_list(ctx->ctx, cipherstr);

  if (rv == 0) {
    return tls_fatal_error(L);
  }

  return 0;
}

static int
tls_sc_set_options(lua_State *L) {
  tls_sc_t *ctx;
  uint64_t opts = 0;

  ctx = getSC(L);

  opts = luaL_checknumber(L, 2);

  SSL_CTX_set_options(ctx->ctx, opts);

  return 0;
}

static X509_STORE *root_cert_store = NULL;

static int
tls_sc_close(lua_State *L) {
  tls_sc_t *sc = getSC(L);

  if (sc->ctx) {
    if (sc->ctx->cert_store == root_cert_store) {
      sc->ctx->cert_store = NULL;
    }
    SSL_CTX_free(sc->ctx);
    sc->ctx = NULL;
  }

  return 0;
}

static int
tls_sc_add_root_certs(lua_State *L) {
  int i;
  tls_sc_t *ctx = getSC(L);

  ERR_clear_error();

  if (!root_cert_store) {
    root_cert_store = X509_STORE_new();

    for (i = 0; root_certs[i]; i++) {
      BIO *bp = BIO_new(BIO_s_mem());
      X509 *x509;

      if (!BIO_write(bp, root_certs[i], strlen(root_certs[i]))) {
        printf("error writing cert %s\n", root_certs[i]);
        BIO_free_all(bp);
        lua_pushboolean(L, 0);
        return 1;
      }

      x509 = PEM_read_bio_X509(bp, NULL, 0, NULL);
      if (x509 == NULL) {
        char buf[1024];
        ERR_error_string(ERR_get_error(), buf);

        printf("error writing x509 cert %s\n", buf);
        BIO_free_all(bp);
        lua_pushboolean(L, 0);
        return 1;
      }

      X509_STORE_add_cert(root_cert_store, x509);

      BIO_free_all(bp);
      X509_free(x509);
    }
  }

  ctx->ca_store = root_cert_store;
  SSL_CTX_set_cert_store(ctx->ctx, ctx->ca_store);

  lua_pushboolean(L, 1);
  return 1;
}

static int
tls_sc_add_crl(lua_State *L) {

  tls_sc_t *ctx = getSC(L);
  X509_CRL *x509;
  BIO *bio;

  bio = _lua_load_bio(L, -1);
  if (!bio) {
    lua_pushboolean(L, 0);
    return 1;
  }

  x509 = PEM_read_bio_X509_CRL(bio, NULL, NULL, NULL);
  if (x509 == NULL) {
    BIO_free_all(bio);
    lua_pushboolean(L, 0);
    return 1;
  }

  X509_STORE_add_crl(ctx->ca_store, x509);
  X509_STORE_set_flags(ctx->ca_store,
                       X509_V_FLAG_CRL_CHECK | X509_V_FLAG_CRL_CHECK_ALL);

  BIO_free_all(bio);
  X509_CRL_free(x509);

  lua_pushboolean(L, 1);
  return 1;
}

int tls_sc_add_ca_cert(lua_State *L)
{
  tls_sc_t *ctx = getSC(L);
  X509 *x509;
  int newCAStore = FALSE;

  if (!ctx->ca_store) {
    ctx->ca_store = X509_STORE_new();
    newCAStore = TRUE;
  }

  x509 = _lua_load_x509(L, 2);
  if (!x509) {
    lua_pushboolean(L, 0);
    return 1;
  }

  X509_STORE_add_cert(ctx->ca_store, x509);
  SSL_CTX_add_client_CA(ctx->ctx, x509);
  X509_free(x509);

  if (newCAStore) {
    SSL_CTX_set_cert_store(ctx->ctx, ctx->ca_store);
  }

  lua_pushboolean(L, 1);
  return 1;
}

static int
tls_sc_gc(lua_State *L) {
  return tls_sc_close(L);
}


static const luaL_reg tls_sc_lib[] = {
  {"setKey", tls_sc_set_key},
  {"setCert", tls_sc_set_cert},
  {"setCiphers", tls_sc_set_ciphers},
  {"setOptions", tls_sc_set_options},
  {"addCACert", tls_sc_add_ca_cert},
  {"addTrustedCert", tls_sc_add_trusted_cert},
  {"addRootCerts", tls_sc_add_root_certs},
  {"addCRL", tls_sc_add_crl},
  {"close", tls_sc_close},
  {"__gc", tls_sc_gc},
  {NULL, NULL}
};

static const luaL_reg tls_lib[] = {
  {"secure_context", tls_sc_create},
  {"connection", luvit__lua_tls_conn_create},
  {NULL, NULL}
};

int
luaopen_tls(lua_State *L)
{
  luaL_newmetatable(L, TLS_SECURE_CONTEXT_HANDLE);
  lua_pushliteral(L, "__index");
  lua_pushvalue(L, -2);  /* push metatable */
  lua_rawset(L, -3);  /* metatable.__index = metatable */
  luaL_openlib(L, NULL, tls_sc_lib, 0);
  lua_pushvalue(L, -1);

  luvit__lua_tls_conn_init(L);

  luaL_openlib(L, "_tls", tls_lib, 1);

#ifdef SSL_OP_ALL
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_ALL);
#endif

#ifdef SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION);
#endif

#ifdef SSL_OP_CIPHER_SERVER_PREFERENCE
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_CIPHER_SERVER_PREFERENCE);
#endif

#ifdef SSL_OP_CISCO_ANYCONNECT
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_CISCO_ANYCONNECT);
#endif

#ifdef SSL_OP_COOKIE_EXCHANGE
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_COOKIE_EXCHANGE);
#endif

#ifdef SSL_OP_CRYPTOPRO_TLSEXT_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_CRYPTOPRO_TLSEXT_BUG);
#endif

#ifdef SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS);
#endif

#ifdef SSL_OP_EPHEMERAL_RSA
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_EPHEMERAL_RSA);
#endif

#ifdef SSL_OP_LEGACY_SERVER_CONNECT
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_LEGACY_SERVER_CONNECT);
#endif

#ifdef SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER);
#endif

#ifdef SSL_OP_MICROSOFT_SESS_ID_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_MICROSOFT_SESS_ID_BUG);
#endif

#ifdef SSL_OP_MSIE_SSLV2_RSA_PADDING
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_MSIE_SSLV2_RSA_PADDING);
#endif

#ifdef SSL_OP_NETSCAPE_CA_DN_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NETSCAPE_CA_DN_BUG);
#endif

#ifdef SSL_OP_NETSCAPE_CHALLENGE_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NETSCAPE_CHALLENGE_BUG);
#endif

#ifdef SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG);
#endif

#ifdef SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG);
#endif

#ifdef SSL_OP_NO_COMPRESSION
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_COMPRESSION);
#endif

#ifdef SSL_OP_NO_QUERY_MTU
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_QUERY_MTU);
#endif

#ifdef SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION);
#endif

#ifdef SSL_OP_NO_SSLv2
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_SSLv2);
#endif

#ifdef SSL_OP_NO_SSLv3
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_SSLv3);
#endif

#ifdef SSL_OP_NO_TICKET
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_TICKET);
#endif

#ifdef SSL_OP_NO_TLSv1
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_TLSv1);
#endif

#ifdef SSL_OP_NO_TLSv1_1
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_TLSv1_1);
#endif

#ifdef SSL_OP_NO_TLSv1_2
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_NO_TLSv1_2);
#endif

#ifdef SSL_OP_PKCS1_CHECK_1
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_PKCS1_CHECK_1);
#endif

#ifdef SSL_OP_PKCS1_CHECK_2
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_PKCS1_CHECK_2);
#endif

#ifdef SSL_OP_SINGLE_DH_USE
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_SINGLE_DH_USE);
#endif

#ifdef SSL_OP_SINGLE_ECDH_USE
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_SINGLE_ECDH_USE);
#endif

#ifdef SSL_OP_SSLEAY_080_CLIENT_DH_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_SSLEAY_080_CLIENT_DH_BUG);
#endif

#ifdef SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG);
#endif

#ifdef SSL_OP_TLS_BLOCK_PADDING_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_TLS_BLOCK_PADDING_BUG);
#endif

#ifdef SSL_OP_TLS_D5_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_TLS_D5_BUG);
#endif

#ifdef SSL_OP_TLS_ROLLBACK_BUG
  LUVIT_DEFINE_CONSTANT(L, SSL_OP_TLS_ROLLBACK_BUG);
#endif

  return 1;
}
