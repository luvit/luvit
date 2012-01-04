#ifndef LUV_DNS
#define LUV_DNS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "ares.h"
#include "utils.h"

typedef struct {
  lua_State* L;
  int r;
  void* buf;
} luv_dns_ref_t;

// Wrapped functions exposed to lua
int luv_dns_queryA(lua_State* L);
int luv_dns_queryAAAA(lua_State* L);
int luv_dns_queryCNAME(lua_State* L);
int luv_dns_queryMX(lua_State* L);
int luv_dns_queryNS(lua_State* L);

void luv_dns_open(void);

#endif
