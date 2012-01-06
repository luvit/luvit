#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lyajl.h"
#include "yajl/yajl_parse.h"
#include "yajl/yajl_version.h"

static int lyajl_on_null (void * ctx) {
  return 1;
}
static int lyajl_on_boolean (void * ctx, int value) {
  return 1;
}
static int lyajl_on_integer (void * ctx, long long value) {
  return 1;
}
static int lyajl_on_double (void * ctx, double value) {
  return 1;
}
static int lyajl_on_string (void * ctx, const unsigned char* value, size_t len) {
  return 1;
}
static int lyajl_on_start_map (void * ctx) {
  return 1;
}
static int lyajl_on_map_key (void * ctx, const unsigned char* key, size_t len) {
  return 1;
}
static int lyajl_on_end_map (void * ctx) {
  return 1;
}
static int lyajl_on_start_array (void * ctx) {
  return 1;
}
static int lyajl_on_end_array (void * ctx) {
  return 1;
}

static yajl_callbacks lyajl_callbacks = {
    lyajl_on_null, lyajl_on_boolean,
    lyajl_on_integer, lyajl_on_double, NULL,
    lyajl_on_string,
    lyajl_on_start_map, lyajl_on_map_key, lyajl_on_end_map,
    lyajl_on_start_array, lyajl_on_end_array
};

static int lyajl_write (lua_State *L) {
  luaL_error(L, "TODO: Implement lyajl_write");
  return 0;
}

static int lyajl_new (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  void* ctx;
  yajl_handle handle = yajl_alloc(&lyajl_callbacks, NULL, ctx);

  lua_newtable (L);
  lua_pushlightuserdata(L, handle);
  lua_setfield(L, -2, "handle");
  lua_pushcfunction(L, lyajl_write);
  lua_setfield(L, -2, "write");
  return 1;
}

LUALIB_API int luaopen_yajl (lua_State *L) {
  // Create a new exports table
  lua_newtable (L);

  // With a single function
  lua_pushcfunction(L, lyajl_new);
  lua_setfield(L, -2, "new");

  // And version info
  lua_pushnumber(L, YAJL_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, YAJL_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");
  lua_pushnumber(L, YAJL_MICRO);
  lua_setfield(L, -2, "VERSION_MICRO");

  // Return the new module
  return 1;
}
