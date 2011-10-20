#ifndef LUV_PROCESS
#define LUV_PROCESS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_handle.h"

int luv_spawn(lua_State* L);
int luv_process_kill(lua_State* L);

#endif
