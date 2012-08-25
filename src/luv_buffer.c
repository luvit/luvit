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

#include <string.h>
#include <stdlib.h>
#include "luv_buffer.h"


/******************************************************************************/

/* Takes as arguments a number or string */
static int luvbuffer_new (lua_State *L) {

  size_t buffer_size;
  const char *lua_temp = NULL;
  if (lua_isnumber(L, 1)) { /* are we perscribing a length */
    buffer_size = (size_t)lua_tonumber(L, 1);
  } else if (lua_isstring(L, 1)) { /* must be a string */
    lua_temp = lua_tolstring(L, 1, &buffer_size);
  } else {
    return luaL_argerror(L, 1, "Must be of type 'Number' or 'String'");
  }

  unsigned char *buffer;
  buffer = (unsigned char*)lua_newuserdata(L, buffer_size + sizeof(size_t) ); /* perhaps this should be aligned? */
  /* store the length of string inside of the beginning of the buffer */
  *((size_t*)(buffer)) = (size_t)buffer_size;

  if (lua_temp) {
    memcpy(buffer + sizeof(size_t), lua_temp, buffer_size);
  } else {
    memset(buffer + sizeof(size_t), '\0', buffer_size);
  }

  /* Set the type of the userdata as an luvbuffer instance */
  luaL_getmetatable(L, "luvbuffer");
  lua_setmetatable(L, -2);

  /* return the userdata */
  return 1;
}

/* tostring(buffer) */
static int luvbuffer_tostring (lua_State *L) {
  unsigned char *buffer = (unsigned char *)luaL_checkudata(L, 1, "luvbuffer");
  size_t buffer_len = *((size_t*)(buffer));

  /* skip first size_t length */
  lua_pushlstring(L, (const char *)buffer + sizeof(size_t), buffer_len);
  return 1;
}

/* __len(buffer) */
static int luvbuffer__len (lua_State *L) {
  unsigned char *buffer = (unsigned char *)luaL_checkudata(L, 1, "luvbuffer");
  size_t buffer_len = *((size_t*)(buffer));

  lua_pushnumber(L, buffer_len);
  return 1;
}

/* __index(buffer, key) */
static int luvbuffer__index (lua_State *L) {
  if (!lua_isnumber(L, 2)) { /* key should be a number */
    lua_getmetatable(L, 1); /*get userdata metatable */
    lua_pushvalue(L, 2);
    lua_rawget(L, -2); /*check environment table for field*/
    return 1; /*luaL_argerror(L, 2, "Must be of type 'Number'");*/
  }

  unsigned char *buffer = (unsigned char *)luaL_checkudata(L, 1, "luvbuffer");
  size_t buffer_len = *((size_t*)(buffer));

  size_t index = (size_t)lua_tonumber(L, 2);
  if (index < 1 || index > buffer_len) {
    return luaL_argerror(L, 2, "Index out of bounds");
  }

  /* skip first size_t length */
  lua_pushlstring(L, (const char *)buffer + sizeof(size_t) + index - 1, 1); /* one character at a time */
  return 1;
}

/* __newindex(buffer, key, value) */
static int luvbuffer__newindex (lua_State *L) {
  if (!lua_isnumber(L, 2)) { /* key should be a number */
    return luaL_argerror(L, 1, "We only support setting indices by type Number");
  }

  unsigned char *buffer = (unsigned char *)luaL_checkudata(L, 1, "luvbuffer");
  size_t buffer_len = *((size_t*)(buffer));

  size_t index = (size_t)lua_tonumber(L, 2);
  if (index < 1 || index > buffer_len) {
    return luaL_argerror(L, 2, "Index out of bounds");
  } else if (!lua_isstring(L, 3)) { /* must be a string */
    return luaL_argerror(L, 3, "Value is not of type String");
  }

  size_t value_len;
  const char *value = lua_tolstring(L, 3, &value_len);

  if (value_len > buffer_len - index - 1) {
    return luaL_argerror(L, 3, "Value is longer than Buffer Length");
  }

  memcpy(buffer + sizeof(size_t) + index - 1, value, value_len);
  return 1;
}


/******************************************************************************/

static const luaL_reg luvbuffer_m[] = {
   {"toString", luvbuffer_tostring}
  ,{"__len", luvbuffer__len}
  ,{"__index", luvbuffer__index}
  ,{"__newindex", luvbuffer__newindex}
  ,{NULL, NULL}
};

static const luaL_reg luvbuffer_f[] = {
   {"new", luvbuffer_new}
  ,{NULL, NULL}
};

LUALIB_API int luaopen_luvbuffer (lua_State *L) {

  /* Create a metatable for the luvbuffer userdata type */
  luaL_newmetatable(L, "luvbuffer");
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  luaL_register(L, NULL, luvbuffer_m);

  /* Create a new exports table */
  lua_newtable (L);
  /* Put our one function on it */
  luaL_register(L, NULL, luvbuffer_f);
  /* Return the new module */
  return 1;
}

