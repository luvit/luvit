/*
** $Id: lcrypto.h,v 1.2 2006/08/25 03:28:32 nezroy Exp $
** See Copyright Notice in license.html
*/

#ifndef _LUACRYPTO_
#define _LUACRYPTO_

#ifndef LUACRYPTO_API
#define LUACRYPTO_API   LUA_API
#endif

#define LUACRYPTO_PREFIX      "LuaCrypto: "
#define LUACRYPTO_CORENAME    "crypto"
#define LUACRYPTO_DIGESTNAME  "crypto.digest"
#define LUACRYPTO_ENCRYPTNAME "crypto.encrypt"
#define LUACRYPTO_DECRYPTNAME "crypto.decrypt"
#define LUACRYPTO_SIGNNAME    "crypto.sign"
#define LUACRYPTO_VERIFYNAME  "crypto.verify"

#define LUACRYPTO_SEALNAME    "crypto.seal"
#define LUACRYPTO_OPENNAME    "crypto.open"

#define LUACRYPTO_HMACNAME    "crypto.hmac"
#define LUACRYPTO_RANDNAME    "crypto.rand"
#define LUACRYPTO_PKEYNAME    "crypto.pkey"
#define LUACRYPTO_X509_CERT_NAME "crypto.x509"
#define LUACRYPTO_X509_CA_NAME "crypto.x509_ca"

LUACRYPTO_API int luacrypto_createmeta (lua_State *L, const char *name, const luaL_reg *methods);
LUACRYPTO_API void luacrypto_setmeta (lua_State *L, const char *name);
LUACRYPTO_API void luacrypto_set_info (lua_State *L);
LUACRYPTO_API int luaopen_crypto(lua_State *L);

#endif
