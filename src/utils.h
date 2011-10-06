#ifndef LUV_UTILS
#define LUV_UTILS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"

// Basically throws an exception using printf style formatting
void error (lua_State *L, const char *fmt, ...);

const char* errno_message(int errorno);
const char* errno_string(int errorno);


#endif
