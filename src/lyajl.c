#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lyajl.h"
#include "utils.h"
#include "yajl/yajl_parse.h"
#include "yajl/yajl_version.h"

static void* yjajl_js_null;

static int lyajl_on_null (void * ctx) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_null");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_boolean (void * ctx, int value) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_boolean");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_pushboolean(L, value);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_integer (void * ctx, long long value) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_number");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_pushnumber(L, value);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_double (void * ctx, double value) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_number");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_pushnumber(L, value);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_string (void * ctx, const unsigned char* value, size_t len) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_string");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_pushlstring(L, (const char*)value, len);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_start_map (void * ctx) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_start_map");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}

static int lyajl_on_map_key (void * ctx, const unsigned char* key, size_t len) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_map_key");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_pushlstring(L, (const char*)key, len);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_end_map (void * ctx) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_end_map");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_start_array (void * ctx) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_start_array");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_end_array (void * ctx) {
  // Load the callback
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "on_end_array");
  lua_remove(L, -2);
  
  // If there is a callback, call it
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}

static yajl_callbacks lyajl_callbacks = {
  lyajl_on_null, lyajl_on_boolean,
  lyajl_on_integer, lyajl_on_double, NULL,
  lyajl_on_string,
  lyajl_on_start_map, lyajl_on_map_key, lyajl_on_end_map,
  lyajl_on_start_array, lyajl_on_end_array
};

static int lyajl_parse (lua_State *L) {
  // Process the args
  luaL_checktype(L, 1, LUA_TTABLE);
  size_t len;
  const char* chunk = luaL_checklstring(L, 2, &len);

  // Load the yajl_handle
  lua_getfield(L, 1, "handle");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "handle is not a proper light userdata");
  }
  yajl_handle handle;
  handle = (yajl_handle)lua_touserdata(L, -1);
  lua_pop(L, 1);

  yajl_status stat;
  stat = yajl_parse(handle, (const unsigned char*)chunk, len);  

  if (stat != yajl_status_ok) {
    unsigned char * str = yajl_get_error(handle, 1, (const unsigned char*)chunk, len);  
    luaL_error(L, (const char *) str);
    yajl_free_error(handle, str); // This doesn't actually happen
  }

  return 0;
}


static int lyajl_new (lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);

  // Use the input as a new table
  lua_pushvalue(L, 1);
  
  // Create a reference to the table
  lua_pushvalue(L, 1);
  luv_ref_t* ref;
  ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;

  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  // Allocate the handle and set as "handle"
  yajl_handle handle = yajl_alloc(&lyajl_callbacks, NULL, (void*)ref);
  lua_pushlightuserdata(L, handle);
  lua_setfield(L, -2, "handle");
  
  lua_getfield(L, -1, "allow_comments");
  int allow_comments = lua_toboolean(L, -1);
  lua_pop(L, 1);
  yajl_config(handle, yajl_allow_comments, allow_comments);
  
  lua_getfield(L, -1, "dont_validate_strings");
  int dont_validate_strings = lua_toboolean(L, -1);
  lua_pop(L, 1);
  yajl_config(handle, yajl_dont_validate_strings, dont_validate_strings);

  // Store a reference to the write method
  lua_pushcfunction(L, lyajl_parse);
  lua_setfield(L, -2, "parse");

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
  
  // Add JS Null
  lua_pushlightuserdata(L, yjajl_js_null);
  lua_setfield(L, -2, "null");

  // Return the new module
  return 1;
}
