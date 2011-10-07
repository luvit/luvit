#ifndef LUV_MISC
#define LUV_MISC

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"

int luv_run(lua_State* L);
int luv_ref (lua_State* L);
int luv_unref(lua_State* L);
int luv_update_time(lua_State* L);
int luv_now(lua_State* L);
int luv_hrtime(lua_State* L);
int luv_get_free_memory(lua_State* L);
int luv_get_total_memory(lua_State* L);
int luv_loadavg(lua_State* L);

#endif
