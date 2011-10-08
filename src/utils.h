#ifndef LUV_UTILS
#define LUV_UTILS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"

// C doesn't have booleans on it's own
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE !FALSE
#endif

void luv_acall(lua_State *L, int nargs, int nresults, const char* source);

const char* errno_message(int errorno);
const char* errno_string(int errorno);

// An alternative to luaL_checkudata that takes inheritance into account for polymorphism
// Make sure to not call with long type strings or strcat will overflow
void* luv_checkudata(lua_State* L, int index, const char* type);

typedef struct {
  lua_State* L;
  int r;
} luv_ref_t;

#endif
