/*
 *  Copyright 2012 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>

#include "lyajl.h"
#include "utils.h"
#include "yajl/yajl_parse.h"
#include "yajl/yajl_gen.h"
#include "yajl/yajl_version.h"

static void* yjajl_js_null;

static int lyajl_on_null (void * ctx) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onNull");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_boolean (void * ctx, int value) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onBoolean");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_pushboolean(L, value);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_integer (void * ctx, long long value) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onNumber");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_pushnumber(L, value);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_double (void * ctx, double value) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onNumber");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_pushnumber(L, value);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_string (void * ctx, const unsigned char* value, size_t len) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onString");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_pushlstring(L, (const char*)value, len);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_start_map (void * ctx) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onStartMap");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}

static int lyajl_on_map_key (void * ctx, const unsigned char* key, size_t len) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onMapKey");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_pushlstring(L, (const char*)key, len);
    lua_call(L, 1, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_end_map (void * ctx) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onEndMap");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_start_array (void * ctx) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onStartArray");
  lua_remove(L, -2);

  /* If there is a callback, call it */
  if (lua_isfunction (L, -1)) {
    lua_call(L, 0, 0);
  } else {
    lua_pop(L, 1);
  }

  return 1;
}
static int lyajl_on_end_array (void * ctx) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_getfield(L, -1, "onEndArray");
  lua_remove(L, -2);

  /* If there is a callback, call it */
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
  size_t len;
  const char *chunk;
  yajl_handle handle;
  yajl_status stat;

  /* Process the args */
  luaL_checktype(L, 1, LUA_TTABLE);
  chunk = luaL_checklstring(L, 2, &len);

  /* Load the yajl_handle */
  lua_getfield(L, 1, "handle");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "handle is not a proper light userdata");
  }

  handle = (yajl_handle)lua_touserdata(L, -1);
  lua_pop(L, 1);

  stat = yajl_parse(handle, (const unsigned char*)chunk, len);

  if (stat != yajl_status_ok) {
    unsigned char * str = yajl_get_error(handle, 1, (const unsigned char*)chunk, len);
    luaL_error(L, (const char *) str);
    yajl_free_error(handle, str); /* This doesn't actually happen */
  }

  return 0;
}

static int lyajl_complete_parse (lua_State *L) {
  yajl_handle handle;
  yajl_status stat;

  /* Process the args */
  luaL_checktype(L, 1, LUA_TTABLE);

  /* Load the yajl_handle */
  lua_getfield(L, 1, "handle");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "handle is not a proper light userdata");
  }
 
  handle = (yajl_handle)lua_touserdata(L, -1);
  lua_pop(L, 1);

  stat = yajl_complete_parse(handle);

  if (stat != yajl_status_ok) {
    unsigned char * str = yajl_get_error(handle, 1, (const unsigned char*)0, 0);
    luaL_error(L, (const char *) str);
    yajl_free_error(handle, str); /* This doesn't actually happen */
  }

  return 0;
}

static int lyajl_config (lua_State *L) {
  const char* option;
  yajl_handle handle;

  /* Process the args */
  luaL_checktype(L, 1, LUA_TTABLE);
  option = luaL_checkstring(L, 2);

  /* Load the yajl_handle */
  lua_getfield(L, 1, "handle");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "handle is not a proper light userdata");
  }

  handle = (yajl_handle)lua_touserdata(L, -1);
  lua_pop(L, 1);

  if (strcmp(option, "allow_comments") == 0) {
    yajl_config(handle, yajl_allow_comments, lua_toboolean(L, 3));
  } else if (strcmp(option, "dont_validate_strings") == 0) {
    yajl_config(handle, yajl_dont_validate_strings, lua_toboolean(L, 3));
  } else if (strcmp(option, "allow_trailing_garbage") == 0) {
    yajl_config(handle, yajl_allow_trailing_garbage, lua_toboolean(L, 3));
  } else if (strcmp(option, "allow_multiple_values") == 0) {
    yajl_config(handle, yajl_allow_multiple_values, lua_toboolean(L, 3));
  } else if (strcmp(option, "allow_partial_values") == 0) {
    yajl_config(handle, yajl_allow_partial_values, lua_toboolean(L, 3));
  } else {
    luaL_error(L, "Invalid config option %s", option);
  }
  return 0;
}


static int lyajl_new_parser (lua_State *L) {
  luv_ref_t* ref;
  yajl_handle handle;

  luaL_checktype(L, 1, LUA_TTABLE);

  /* Use the input as a new table */
  lua_pushvalue(L, 1);

  /* Create a reference to the table */
  lua_pushvalue(L, 1);

  ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;

  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  /* Allocate the handle and set as "handle" */
  handle = yajl_alloc(&lyajl_callbacks, NULL, (void*)ref);
  lua_pushlightuserdata(L, handle);
  lua_setfield(L, -2, "handle");

  lua_getfield(L, LUA_REGISTRYINDEX, "yajl_parser_meta");
  lua_setmetatable(L, -2);

  return 1;
}

static int lyajl_gen_null (lua_State *L) {
  yajl_gen generator;
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_null(generator);
  return 0;
}

static int lyajl_gen_boolean (lua_State *L) {
  int value;
  yajl_gen generator;
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checktype(L, 2, LUA_TBOOLEAN);
  value = lua_toboolean(L, 2);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_bool(generator, value);
  return 0;
}

static int lyajl_gen_number (lua_State *L) {
  size_t len;
  const char *value;
  yajl_gen generator;

  luaL_checktype(L, 1, LUA_TTABLE);

  value = luaL_checklstring(L, 2, &len);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_number(generator, value, len);
  return 0;
}

static int lyajl_gen_string (lua_State *L) {
  size_t len;
  const char *value;
  yajl_gen generator;

  luaL_checktype(L, 1, LUA_TTABLE);

  value = luaL_checklstring(L, 2, &len);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_string(generator, (const unsigned char*)value, len);
  return 0;
}

static int lyajl_gen_map_open (lua_State *L) {
  yajl_gen generator;
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_map_open(generator);
  return 0;
}

static int lyajl_gen_map_close (lua_State *L) {
  yajl_gen generator;
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_map_close(generator);
  return 0;
}

static int lyajl_gen_array_open (lua_State *L) {
  yajl_gen generator;
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_array_open(generator);
  return 0;
}

static int lyajl_gen_array_close (lua_State *L) {
  yajl_gen generator;
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);
  yajl_gen_array_close(generator);
  return 0;
}

static int lyajl_gen_get_buf (lua_State *L) {
  yajl_gen generator;
  const unsigned char *buf;
  size_t len;

  luaL_checktype(L, 1, LUA_TTABLE);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);

  yajl_gen_get_buf(generator, &buf, &len);
  lua_pushlstring(L, (const char*)buf, len);
  yajl_gen_clear(generator);
  return 1;
}

int lyajl_gen_on_print(void* ctx, const char* string, size_t len) {
  /* Load the callback */
  luv_ref_t* ref = ctx;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  lua_pushlstring(L, string, len);
  lua_call(L, 1, 0);
  return 1;
}

static int lyajl_gen_config (lua_State *L) {
  const char *option;
  yajl_gen generator;
  luv_ref_t* ref;

  luaL_checktype(L, 1, LUA_TTABLE);
  option = luaL_checkstring(L, 2);
  lua_getfield(L, 1, "generator");
  if (!lua_islightuserdata(L, -1)) {
    luaL_error(L, "generator is not a proper light userdata");
  }
  generator = (yajl_gen)lua_touserdata(L, -1);
  lua_pop(L, 1);

  if (strcmp(option, "beautify") == 0) {
    yajl_gen_config(generator, yajl_gen_beautify, lua_toboolean(L, 3));
  } else if (strcmp(option, "indent_string") == 0) {
    yajl_gen_config(generator, yajl_gen_indent_string, luaL_checkstring(L, 3));
  } else if (strcmp(option, "print_callback") == 0) {
    if (lua_isfunction (L, 3) == 0) {
      luaL_error(L, "Print callback config must be a function");
    }

    ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
    ref->L = L;
    lua_pushvalue(L, 3);
    ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
    yajl_gen_config(generator, yajl_gen_print_callback, lyajl_gen_on_print, (void*)ref);
  } else if (strcmp(option, "validate_utf8") == 0) {
    yajl_gen_config(generator, yajl_gen_validate_utf8, lua_toboolean(L, 3));
  } else if (strcmp(option, "escape_solidus") == 0) {
    yajl_gen_config(generator, yajl_gen_escape_solidus, lua_toboolean(L, 3));
  } else {
    luaL_error(L, "Invalid configuration option %s", option);
  }
  return 0;
}


static int lyajl_new_generator (lua_State *L) {
  yajl_gen generator;
  lua_newtable(L);

  generator = yajl_gen_alloc(NULL);
  lua_pushlightuserdata(L, generator);
  lua_setfield(L, -2, "generator");

  lua_getfield(L, LUA_REGISTRYINDEX, "yajl_generator_meta");
  lua_setmetatable(L, -2);

  return 1;
}

static const luaL_reg lyajl_parser_m[] = {
  {"parse", lyajl_parse},
  {"complete", lyajl_complete_parse},
  {"config", lyajl_config},
  {NULL, NULL}
};

static const luaL_reg lyajl_gen_m[] = {
  {"null", lyajl_gen_null},
  {"boolean", lyajl_gen_boolean},
  {"number", lyajl_gen_number},
  {"string", lyajl_gen_string},
  {"mapOpen", lyajl_gen_map_open},
  {"mapClose", lyajl_gen_map_close},
  {"arrayOpen", lyajl_gen_array_open},
  {"arrayClose", lyajl_gen_array_close},
  {"getBuf", lyajl_gen_get_buf},
  {"config", lyajl_gen_config},
  {NULL, NULL}
};

LUALIB_API int luaopen_yajl (lua_State *L) {

  /* Build parser metatable */
  lua_newtable(L);
  lua_newtable(L);
  luaL_register(L, NULL, lyajl_parser_m);
  lua_setfield(L, -2, "__index");
  lua_setfield(L, LUA_REGISTRYINDEX, "yajl_parser_meta");

  /* Build generator metatable */
  lua_newtable(L);
  lua_newtable(L);
  luaL_register(L, NULL, lyajl_gen_m);
  lua_setfield(L, -2, "__index");
  lua_setfield(L, LUA_REGISTRYINDEX, "yajl_generator_meta");

  /* Create a new exports table */
  lua_newtable(L);

  /* With a single function */
  lua_pushcfunction(L, lyajl_new_parser);
  lua_setfield(L, -2, "newParser");
  lua_pushcfunction(L, lyajl_new_generator);
  lua_setfield(L, -2, "newGenerator");

  /* And version info */
  lua_pushnumber(L, YAJL_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, YAJL_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");
  lua_pushnumber(L, YAJL_MICRO);
  lua_setfield(L, -2, "VERSION_MICRO");

  /* Add JS Null */
  lua_pushlightuserdata(L, yjajl_js_null);
  lua_setfield(L, -2, "null");

  /* Return the new module */
  return 1;
}
