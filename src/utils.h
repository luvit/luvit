#ifndef LUV_UTILS
#define LUV_UTILS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "ares.h"

// C doesn't have booleans on it's own
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE !FALSE
#endif

void luv_acall(lua_State *L, int nargs, int nresults, const char* source);

void luv_set_loop(lua_State *L, uv_loop_t *loop);
uv_loop_t* luv_get_loop(lua_State *L);

void luv_set_ares_channel(lua_State *L, ares_channel *channel);
ares_channel* luv_get_ares_channel(lua_State *L);


void luv_push_async_error(lua_State* L, uv_err_t err, const char* source, const char* path);
void luv_push_async_error_raw(lua_State* L, const char *code, const char *msg, const char* source, const char* path);

// An alternative to luaL_checkudata that takes inheritance into account for polymorphism
// Make sure to not call with long type strings or strcat will overflow
void* luv_checkudata(lua_State* L, int index, const char* type);

const char* luv_handle_type_to_string(uv_handle_type type);


typedef struct {
  lua_State* L;
  int r;
} luv_ref_t;

#endif
