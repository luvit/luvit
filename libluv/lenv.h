#ifndef LENV
#define LENV

//#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"
#include "utils.h"

LUALIB_API int luaopen_env (lua_State *L);

#endif
