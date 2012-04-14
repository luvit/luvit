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

typedef struct {
  lua_State* L;
  int r;
} luv_ref_t;


#define JSON_PARSER_HANDLE "llyajl_parser_handle"
#define JSON_GENERATOR_HANDLE "llyajl_generator_handle"

typedef struct luvit_parser_t {
  luv_ref_t *ref;
  yajl_handle handle;
} luvit_parser_t;

typedef struct luvit_generator_t {
  yajl_gen gen;
} luvit_generator_t;

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

luvit_parser_t* parser_get(lua_State *L, int index) {
  return luaL_checkudata(L, index, JSON_PARSER_HANDLE);
}

luvit_parser_t* parser_new(lua_State *L) {
  luvit_parser_t *parser = lua_newuserdata(L, sizeof(*parser));
  return parser;
}

luvit_generator_t* generator_get(lua_State *L, int index) {
  return luaL_checkudata(L, index, JSON_GENERATOR_HANDLE);
}

luvit_generator_t* generator_new(lua_State *L) {
  luvit_generator_t *generator = lua_newuserdata(L, sizeof(*generator));
  generator->gen = yajl_gen_alloc(NULL);
  luaL_getmetatable(L, JSON_GENERATOR_HANDLE);
  lua_setmetatable(L, -2);
  return generator;
}

static int lyajl_parse (lua_State *L) {
  size_t len;
  const char *chunk;
  luvit_parser_t *parser;
  yajl_status stat;

  /* Process the args */
  parser = parser_get(L, 1);
  chunk = luaL_checklstring(L, 2, &len);

  stat = yajl_parse(parser->handle, (const unsigned char*)chunk, len);

  if (stat != yajl_status_ok) {
    unsigned char * str = yajl_get_error(parser->handle, 1, (const unsigned char*)chunk, len);
    luaL_error(L, (const char *) str);
    yajl_free_error(parser->handle, str); /* This doesn't actually happen */
  }

  return 0;
}

static int lyajl_complete_parse (lua_State *L) {
  yajl_status stat;
  luvit_parser_t *parser = parser_get(L, 1);

  /* Process the args */
  stat = yajl_complete_parse(parser->handle);

  /* Unreference the callback */
  luaL_unref(L, LUA_REGISTRYINDEX, parser->ref->r);

  if (stat != yajl_status_ok) {
    unsigned char * str = yajl_get_error(parser->handle, 1, (const unsigned char*)0, 0);
    luaL_error(L, (const char *) str);
    yajl_free_error(parser->handle, str); /* This doesn't actually happen */
  }

  return 0;
}

static int lyajl_config (lua_State *L) {
  const char* option;
  luvit_parser_t *parser = parser_get(L, 1);

  option = luaL_checkstring(L, 2);

  if (strcmp(option, "allow_comments") == 0) {
    yajl_config(parser->handle, yajl_allow_comments, lua_toboolean(L, 3));
  } else if (strcmp(option, "dont_validate_strings") == 0) {
    yajl_config(parser->handle, yajl_dont_validate_strings, lua_toboolean(L, 3));
  } else if (strcmp(option, "allow_trailing_garbage") == 0) {
    yajl_config(parser->handle, yajl_allow_trailing_garbage, lua_toboolean(L, 3));
  } else if (strcmp(option, "allow_multiple_values") == 0) {
    yajl_config(parser->handle, yajl_allow_multiple_values, lua_toboolean(L, 3));
  } else if (strcmp(option, "allow_partial_values") == 0) {
    yajl_config(parser->handle, yajl_allow_partial_values, lua_toboolean(L, 3));
  } else {
    luaL_error(L, "Invalid config option %s", option);
  }
  return 0;
}


static int lyajl_new_parser (lua_State *L) {
  int r = luaL_ref(L, LUA_REGISTRYINDEX);
  luvit_parser_t *parser = parser_new(L);
  parser->ref = malloc(sizeof(luv_ref_t));
  parser->ref->L = L;
  parser->ref->r = r;
  parser->handle = yajl_alloc(&lyajl_callbacks, NULL, (void*)parser->ref);
  luaL_getmetatable(L, JSON_PARSER_HANDLE);
  lua_setmetatable(L, -2);
  return 1;
}

static int lyajl_new_generator (lua_State *L) {
  generator_new(L);
  return 1;
}

static int lyajl_parser_gc (lua_State *L) {
  luvit_parser_t *parser = parser_get(L, 1);
  yajl_free(parser->handle);
  free(parser->ref);
  return 0;
}

static int lyajl_gen_null (lua_State *L) {
  luvit_generator_t *generator = generator_get(L, 1);
  yajl_gen_null(generator->gen);
  return 0;
}

static int lyajl_gen_boolean (lua_State *L) {
  int value;
  luvit_generator_t *generator = generator_get(L, 1);
  value = lua_toboolean(L, 2);
  yajl_gen_bool(generator->gen, value);
  return 0;
}

static int lyajl_gen_number (lua_State *L) {
  size_t len;
  const char *value;
  luvit_generator_t *generator = generator_get(L, 1);
  value = luaL_checklstring(L, 2, &len);
  yajl_gen_number(generator->gen, value, len);
  return 0;
}

static int lyajl_gen_string (lua_State *L) {
  size_t len;
  const char *value;
  luvit_generator_t *generator = generator_get(L, 1);
  value = luaL_checklstring(L, 2, &len);
  yajl_gen_string(generator->gen, (const unsigned char*)value, len);
  return 0;
}

static int lyajl_gen_map_open (lua_State *L) {
  luvit_generator_t *generator = generator_get(L, 1);
  yajl_gen_map_open(generator->gen);
  return 0;
}

static int lyajl_gen_map_close (lua_State *L) {
  luvit_generator_t *generator = generator_get(L, 1);
  yajl_gen_map_close(generator->gen);
  return 0;
}

static int lyajl_gen_array_open (lua_State *L) {
  luvit_generator_t *generator = generator_get(L, 1);
  yajl_gen_array_open(generator->gen);
  return 0;
}

static int lyajl_gen_array_close (lua_State *L) {
  luvit_generator_t *generator = generator_get(L, 1);
  yajl_gen_array_close(generator->gen);
  return 0;
}

static int lyajl_gen_get_buf (lua_State *L) {
  const unsigned char *buf;
  size_t len;
  luvit_generator_t *generator = generator_get(L, 1);
  yajl_gen_get_buf(generator->gen, &buf, &len);
  lua_pushlstring(L, (const char*)buf, len);
  yajl_gen_clear(generator->gen);
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
  luv_ref_t* ref;
  luvit_generator_t *generator = generator_get(L, 1);
  option = luaL_checkstring(L, 2);

  if (strcmp(option, "beautify") == 0) {
    yajl_gen_config(generator->gen, yajl_gen_beautify, lua_toboolean(L, 3));
  } else if (strcmp(option, "indent_string") == 0) {
    yajl_gen_config(generator->gen, yajl_gen_indent_string, luaL_checkstring(L, 3));
  } else if (strcmp(option, "print_callback") == 0) {
    if (lua_isfunction (L, 3) == 0) {
      luaL_error(L, "Print callback config must be a function");
    }

    ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
    ref->L = L;
    lua_pushvalue(L, 3);
    ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
    yajl_gen_config(generator->gen, yajl_gen_print_callback, lyajl_gen_on_print, (void*)ref);
  } else if (strcmp(option, "validate_utf8") == 0) {
    yajl_gen_config(generator->gen, yajl_gen_validate_utf8, lua_toboolean(L, 3));
  } else if (strcmp(option, "escape_solidus") == 0) {
    yajl_gen_config(generator->gen, yajl_gen_escape_solidus, lua_toboolean(L, 3));
  } else {
    luaL_error(L, "Invalid configuration option %s", option);
  }
  return 0;
}

static int lyajl_gen_gc(lua_State *L) {
  luvit_generator_t *generator = generator_get(L, 1);
  yajl_gen_free(generator->gen);
  return 0;
}

static const luaL_reg lyajl_parser_m[] = {
  {"parse", lyajl_parse},
  {"complete", lyajl_complete_parse},
  {"config", lyajl_config},
  {"__gc", lyajl_parser_gc},
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
  {"__gc", lyajl_gen_gc},
  {NULL, NULL}
};

static const luaL_reg lyajl_lib[] = {
  {"newParser", lyajl_new_parser},
  {"newGenerator", lyajl_new_generator},
  {NULL, NULL}
};

LUALIB_API int luaopen_yajl (lua_State *L) {

  luaL_newmetatable(L, JSON_PARSER_HANDLE);
  lua_pushliteral(L, "__index");
  lua_pushvalue(L, -2);  /* push metatable */
  lua_rawset(L, -3);  /* metatable.__index = metatable */
  luaL_openlib(L, NULL, lyajl_parser_m, 0);
  lua_pushvalue(L, -1);

  luaL_newmetatable(L, JSON_GENERATOR_HANDLE);
  lua_pushliteral(L, "__index");
  lua_pushvalue(L, -2);  /* push metatable */
  lua_rawset(L, -3);  /* metatable.__index = metatable */
  luaL_openlib(L, NULL, lyajl_gen_m, 0);
  lua_pushvalue(L, -1);

  luaL_openlib(L, "_yajl", lyajl_lib, 1);

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
