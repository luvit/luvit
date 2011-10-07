#ifndef LUV_TTY
#define LUV_TTY

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_stream.h"

int luv_new_tty (lua_State* L);
int luv_tty_set_mode(lua_State* L);
int luv_tty_reset_mode(lua_State* L);
int luv_tty_get_winsize(lua_State* L);

#endif
