#ifndef TOPCUBE
#define TOPCUBE

#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

LUALIB_API int luaopen_topcube (lua_State *L);

#endif
