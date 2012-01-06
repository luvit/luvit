#ifndef LUV_DNS
#define LUV_DNS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "ares.h"
#include "utils.h"

// Wrapped functions exposed to lua
int luv_dns_queryA(lua_State* L);
int luv_dns_queryAAAA(lua_State* L);
int luv_dns_queryCNAME(lua_State* L);
int luv_dns_queryMX(lua_State* L);
int luv_dns_queryNS(lua_State* L);
int luv_dns_queryTXT(lua_State* L);
int luv_dns_querySRV(lua_State* L);
int luv_dns_getHostByAddr(lua_State* L);
int luv_dns_getAddrInfo(lua_State* L);

int luv_dns_isIP(lua_State* L);
int luv_dns_isIPv4(lua_State* L);
int luv_dns_isIPv6(lua_State* L);

void luv_dns_open(void);

#endif
