#ifndef LYAJL
#define LYAJL

//#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"
#include "utils.h"

LUALIB_API int luaopen_yajl (lua_State *L);

#endif
