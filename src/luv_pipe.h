#ifndef LUV_PIPE
#define LUV_PIPE

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_stream.h"

int luv_new_pipe (lua_State* L);
int luv_pipe_open(lua_State* L);
int luv_pipe_bind(lua_State* L);
int luv_pipe_connect(lua_State* L);

#endif
