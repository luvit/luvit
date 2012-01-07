#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "lyajl.h"
#include "utils.h"
#include "yajl/yajl_parse.h"
#include "yajl/yajl_version.h"

static int lyajl_on_null (void * ctx) {
  printf("on_null\n");
  return 1;
}
static int lyajl_on_boolean (void * ctx, int value) {
  printf("on_boolean\n");
  return 1;
}
static int lyajl_on_integer (void * ctx, long long value) {
  printf("on_integer\n");
  return 1;
}
static int lyajl_on_double (void * ctx, double value) {
  printf("on_double\n");
  return 1;
}
static int lyajl_on_string (void * ctx, const unsigned char* value, size_t len) {
  printf("on_string\n");
  return 1;
}
static int lyajl_on_start_map (void * ctx) {
  printf("on_start_map\n");
  
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_start_map");
  lua_remove(L, -2);
  
  // See if it's a function
  if (lua_isfunction (L, -1) == 0) {
    printf("MISSING CALLBACK\n");
    // no function defined
    lua_pop(L, 1);
    return 1;
  };
  printf("FOUND IT!\n");

  lua_call(L, 0, 0);


  return 1;
}

static int lyajl_on_map_key (void * ctx, const unsigned char* key, size_t len) {
  printf("on_map_key\n");
  return 1;
}
static int lyajl_on_end_map (void * ctx) {
  printf("on_end_map\n");
  return 1;
}
static int lyajl_on_start_array (void * ctx) {
  printf("on_start_array\n");
  return 1;
}
static int lyajl_on_end_array (void * ctx) {
  printf("on_end_array\n");
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
  // Process the args
  luaL_checktype(L, 1, LUA_TTABLE);
  size_t len;
  const char* chunk = luaL_checklstring(L, 2, &len);

  int before = lua_gettop(L);

  // Load the yajl_handle
  lua_getfield(L, 1, "handle");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "handle is not a proper light userdata");
  }
  yajl_handle handle;
  handle = (yajl_handle)lua_touserdata(L, -1);
  lua_pop(L, 1);

  assert(lua_gettop(L) == before);

  yajl_status stat;
  printf("Parsing: '%s' %d\n", chunk, (int)len);
  stat = yajl_parse(handle, (const unsigned char*)chunk, len);  
  printf("Stat %d, %d\n", stat, yajl_status_ok);

  if (stat != yajl_status_ok) {
    unsigned char * str = yajl_get_error(handle, 1, (const unsigned char*)chunk, len);  
    luaL_error(L, (const char *) str);
    yajl_free_error(handle, str); // This doesn't actually happen
  }

  assert(lua_gettop(L) == before);

  return 0;
}

static int lyajl_new (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);

  int before = lua_gettop(L);
  
  // Use the input as a new table
  lua_pushvalue(L, 1);

  assert(lua_gettop(L) == before + 1);
  
  // Create a reference to the table
  lua_pushvalue(L, 1);
  luv_ref_t* ref;
  ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;
  ref->r = luaL_ref(L, -1);

  assert(lua_gettop(L) == before + 1);
  
  // Allocate the handle and set as "handle"
  yajl_handle handle = yajl_alloc(&lyajl_callbacks, NULL, (void*)ref);
  lua_pushlightuserdata(L, handle);
  lua_setfield(L, -2, "handle");
  
  // TODO: read config options that aren't callbacks and set them on the parser
  assert(lua_gettop(L) == before + 1);

  // Store a reference to the write method
  lua_pushcfunction(L, lyajl_write);
  lua_setfield(L, -2, "write");

  assert(lua_gettop(L) == before + 1);
  
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
