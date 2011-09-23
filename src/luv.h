#ifndef LUV
#define LUV

//#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"
#include "utils.h"

LUALIB_API int luaopen_uv (lua_State *L);

#endif

