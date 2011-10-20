#ifndef LHTTP_PARSER
#define LHTTP_PARSER

//#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"
#include "utils.h"

LUALIB_API int luaopen_http_parser (lua_State *L);

#endif
