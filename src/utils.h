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

void luv_push_async_error(lua_State* L, uv_err_t err, const char* source, const char* path);

// An alternative to luaL_checkudata that takes inheritance into account for polymorphism
// Make sure to not call with long type strings or strcat will overflow
void* luv_checkudata(lua_State* L, int index, const char* type);

const char* luv_handle_type_to_string(uv_handle_type type);


typedef struct {
  lua_State* L;
  int r;
} luv_ref_t;

#endif
