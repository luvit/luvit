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

#if defined(_MSC_VER)
/* Ah, MSVC */
typedef __int8 int8_t;
typedef __int16 int16_t;
typedef __int32 int32_t;
typedef __int64 int64_t;
typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int32 uint32_t;
typedef __int32 intptr_t;
typedef unsigned __int32 uintptr_t;
#else
#include <stdint.h>
#endif

/* MSVC Built-in */
#if defined(_MSC_VER)
/* http://msdn.microsoft.com/en-us/library/a3140177.aspx */
#define __bswap16   _byteswap_ushort
#define __bswap32   _byteswap_ulong
/* GCC Built-in */
#elif (__GNUC__ > 4) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3)
/* http://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html */

  /* NOOP */

/* x86 */
#elif defined(__i386__) || defined(__x86_64__)
static uint32_t __builtin_bswap32(uint32_t x)
{
  uint32_t r; __asm__("bswap %0" : "=r" (r) : "0" (x)); return r;
}
/* other platforms */
#else
static uint32_t __builtin_bswap32(uint32_t x)
{
  return (x << 24) | ((x & 0xff00) << 8) | ((x >> 8) & 0xff00) | (x >> 24);
}
#endif

#if !defined( _MSC_VER )
/* NON MSVC solutions require defining __builtin_bswap16 */
static uint16_t __builtin_bswap16( uint16_t a ) {
  return (a<<8)|(a>>8);
}
#define __bswap16   __builtin_bswap16
#define __bswap32   __builtin_bswap32
#endif

/******************************************************************************/

#define BUFFER_UDATA(L)                                                        \
  unsigned char *buffer = (unsigned char *)luaL_checkudata(L, 1, "luvbuffer"); \
  size_t buffer_len = *((size_t*)(buffer));                                    \
  buffer += sizeof(size_t);                                                    \

#define _BUFFER_GETOFFSET(L, _idx, extbound)               \
  size_t index = (size_t)lua_tonumber(L, _idx);            \
  if (index < 1 || index > buffer_len - extbound) {        \
    return luaL_argerror(L, _idx, "Index out of bounds");  \
  }

#define BUFFER_GETOFFSET(L, _idx) _BUFFER_GETOFFSET(L, _idx, 0)

void * lua_resizeuserdata(lua_State *L, int index, size_t size) {
  unsigned char *new_buffer;

  unsigned char *old_buffer = (unsigned char *)luaL_checkudata(L, index, "luvbuffer");
  size_t old_buffer_len = *((size_t*)(old_buffer));
  old_buffer += sizeof(size_t);

  new_buffer = (unsigned char*)lua_newuserdata(L, size + sizeof(size_t) );
  /* store the length of string inside of the beginning of the buffer */
  *((size_t*)(new_buffer)) = (size_t)size;

  /* copy old contents to new userdata */
  memcpy(
     new_buffer + sizeof(size_t)
    ,old_buffer
    ,(size > old_buffer_len ? old_buffer_len : size)
  );

  return new_buffer + sizeof(size_t);
}

/******************************************************************************/

/* Takes as arguments a number or string */
static int luvbuffer_new (lua_State *L) {
  size_t buffer_size;
  const char *lua_temp = NULL;
  unsigned char *buffer;

  int init_idx = 1;

  int entry_type = lua_type(L, 1);
  if (LUA_TTABLE == entry_type) {
    init_idx++;
  }

  if (lua_isnumber(L, init_idx)) { /* are we perscribing a length */
    buffer_size = (size_t)lua_tonumber(L, init_idx);
  } else if (lua_isstring(L, init_idx)) { /* must be a string */
    lua_temp = lua_tolstring(L, init_idx, &buffer_size);
  } else {
    return luaL_argerror(L, init_idx, "Must be of type 'Number' or 'String'");
  }

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


/* isBuffer( obj ) */
static int luvbuffer_isbuffer (lua_State *L) {
  int is_buffer = 0;

  void*p=lua_touserdata(L, 1);
  if(p!=NULL){
    if(lua_getmetatable(L,1)){
      lua_getfield(L,(-10000),"luvbuffer");
      if(lua_rawequal(L,-1,-2)){
        lua_pop(L,2);
        is_buffer = 1;
      }
    }
  }

  lua_pushboolean(L, is_buffer);
  return 1;
}

/******************************************************************************/

/* tostring(buffer, i, j) */
static int luvbuffer_tostring (lua_State *L) {
  BUFFER_UDATA(L)

  size_t offset = (size_t)lua_tonumber(L, 2);
  if (!offset) {
    offset = 1;
  }
  if (offset < 1 || offset > buffer_len) {
    return luaL_argerror(L, 2, "Offset out of bounds");
  }
  offset--; /* account for Lua-isms */

  size_t length = (size_t)lua_tonumber(L, 3);
  if (!length) {
    length = buffer_len;
  }
  if (length < offset || length > buffer_len) {
    return luaL_argerror(L, 3, "length out of bounds");
  }

  /* skip first size_t length */
  lua_pushlstring(L, (const char *)buffer + offset, length - offset);
  return 1;
}

/* fill(buffer, char, i, j) */
static int luvbuffer_fill (lua_State *L) {
  BUFFER_UDATA(L)

  size_t offset = (size_t)lua_tonumber(L, 3);
  if (!offset) {
    offset = 1;
  }
  if (offset < 1 || offset > buffer_len) {
    return luaL_argerror(L, 3, "Offset out of bounds");
  }
  offset--; /* account for Lua-isms */

  size_t length = (size_t)lua_tonumber(L, 4);
  if (!length) {
    length = buffer_len;
  }
  if (length < offset || length > buffer_len) {
    return luaL_argerror(L, 4, "length out of bounds");
  }

  uint8_t value;

  if (lua_isnumber(L, 2)) {
    value = (uint8_t)lua_tonumber(L, 2); /* using value_len here as value */
    if (value > 255) {
      return luaL_argerror(L, 2, "0 < Value < 255");
    }
  } else if (lua_isstring(L, 2)) {
    value = *((uint8_t*)lua_tolstring(L, 2, NULL));
  } else {
    return luaL_argerror(L, 2, "Value is not of type 'String' or 'Number'");
  }

  memset(buffer + offset, value, length - offset);
  lua_pushnil(L);
  return 1;
}

static const char _hex[] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

/* inspect(buffer) */

static int luvbuffer_inspect (lua_State *L) {
  int i;

  BUFFER_UDATA(L)

  size_t str_len = 8 /* <Buffer */
                 + buffer_len*3 /* buf_len hex+space */
                 + 1 /* > */
                 ;

  char *str = (char *)malloc(str_len);
  char *t = str;
  sprintf(str, "<Buffer ");
  t = t + 8;
  for(i=0;i<buffer_len;i++) {
    *((char *)t) = _hex[(buffer[i] >> 4)];
    *((char *)(t+1)) = _hex[(buffer[i] % 0x10)];
    *((char *)(t+2)) = ' ';
    t = t + 3;
  }
  *((char *)t) = '>';

  lua_pushlstring(L, str, str_len);
  free( str );
  return 1;
}

/* upuntil(buffer, i, j) */
static int luvbuffer_upuntil (lua_State *L) {
  size_t delimiter_len;
  const char *delimiter_buf = NULL;
  const char *found = NULL;

  BUFFER_UDATA(L)

  delimiter_buf = lua_tolstring(L, 2, &delimiter_len);
  if (!delimiter_buf) {
    return luaL_argerror(L, 2, "Delimiter String is Required");
  }

  size_t offset = (size_t)lua_tonumber(L, 3);
  if (!offset) {
    offset = 1;
  }
  if (offset < 1 || offset > buffer_len) {
    return luaL_argerror(L, 3, "Offset out of bounds");
  }
  offset--; /* account for Lua-isms */

  /* use memmem to find first instance of our delimiter */
  found = memmem(
             (const char *)buffer + offset
            ,buffer_len - offset
            ,delimiter_buf
            ,delimiter_len
          );

  if (!found) { /* if nothing is found, return from offset */
    lua_pushlstring(L, (const char *)buffer + offset, buffer_len - offset);
  } else {
    lua_pushlstring(L, 
       (const char *)buffer + offset
      ,found - ((const char *)buffer) - offset
    );
  }
  return 1;
}

/* readInt8(buffer, offset) */
static int luvbuffer_readInt8 (lua_State *L) {
  BUFFER_UDATA(L)

  BUFFER_GETOFFSET(L, 2) /* sets index */

  lua_pushnumber(L, *((int8_t*)(buffer + index - 1)));
  return 1;
}

/* readUInt16LE(buffer, offset) */
static int luvbuffer_readUInt16BE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 2, 1) /* sets index */

  lua_pushnumber(L, __bswap16( *((uint16_t*)(buffer + index - 1)) ) );
  return 1;
}

/* readUInt16LE(buffer, offset) */
static int luvbuffer_readUInt16LE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 2, 1) /* sets index */

  lua_pushnumber(L, *((uint16_t*)(buffer + index - 1)));
  return 1;
}

/* readUInt32LE(buffer, offset) */
static int luvbuffer_readUInt32BE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 2, 3) /* sets index */

  lua_pushnumber(L, __bswap32( *((uint32_t*)(buffer + index - 1)) ) );
  return 1;
}


/* readUInt32LE(buffer, offset) */
static int luvbuffer_readUInt32LE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 2, 3) /* sets index */

  lua_pushnumber(L, *((uint32_t*)(buffer + index - 1)));
  return 1;
}

/* readInt32LE(buffer, offset) */
static int luvbuffer_readInt32BE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 2, 3) /* sets index */

  lua_pushnumber(L, (int32_t)__bswap32( *((uint32_t*)(buffer + index - 1)) ) );
  return 1;
}


/* readInt32LE(buffer, offset) */
static int luvbuffer_readInt32LE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 2, 3) /* sets index */

  lua_pushnumber(L, *((int32_t*)(buffer + index - 1)));
  return 1;
}

/* writeUInt8(buffer, value, offset) */
static int luvbuffer_writeUInt8 (lua_State *L) {
  BUFFER_UDATA(L)

  BUFFER_GETOFFSET(L, 3) /* sets index */

  *((uint8_t*)(buffer + index - 1)) = luaL_checknumber(L, 2);

  lua_pushnil(L);
  return 1;
}


/* writeInt8(buffer, value, offset) */
static int luvbuffer_writeInt8 (lua_State *L) {
  BUFFER_UDATA(L)

  BUFFER_GETOFFSET(L, 3) /* sets index */

  *((int8_t*)(buffer + index - 1)) = luaL_checknumber(L, 2);
  lua_pushnil(L);
  return 1;
}

/* writeUInt16LE(buffer, value, offset) */
static int luvbuffer_writeUInt16BE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 3, 1) /* sets index */

  *((uint16_t*)(buffer + index - 1)) = __bswap16( luaL_checknumber(L, 2) );
  lua_pushnil(L);
  return 1;
}

/* writeUInt16LE(buffer, value, offset) */
static int luvbuffer_writeUInt16LE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 3, 1) /* sets index */

  *((uint16_t*)(buffer + index - 1)) = luaL_checknumber(L, 2);
  lua_pushnil(L);
  return 1;
}

/* writeUInt32LE(buffer, value, offset) */
static int luvbuffer_writeUInt32BE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 3, 3) /* sets index */

  *((uint32_t*)(buffer + index - 1)) = __bswap32( luaL_checknumber(L, 2) );
  lua_pushnil(L);
  return 1;
}


/* writeUInt32LE(buffer, value, offset) */
static int luvbuffer_writeUInt32LE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 3, 3) /* sets index */

  *((uint32_t*)(buffer + index - 1)) = luaL_checknumber(L, 2);
  lua_pushnil(L);
  return 1;
}

/* writeInt32LE(buffer, value, offset) */
static int luvbuffer_writeInt32BE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 3, 3) /* sets index */

  *((int32_t*)(buffer + index - 1)) = __bswap32( luaL_checknumber(L, 2) );
  lua_pushnil(L);
  return 1;
}


/* writeInt32LE(buffer, write, offset) */
static int luvbuffer_writeInt32LE (lua_State *L) {
  BUFFER_UDATA(L)

  _BUFFER_GETOFFSET(L, 3, 3) /* sets index */

  *((int32_t*)(buffer + index - 1)) = luaL_checknumber(L, 2);
  lua_pushnil(L);
  return 1;
}

/* __len(buffer) */
static int luvbuffer__len (lua_State *L) {
  BUFFER_UDATA(L)

  lua_pushnumber(L, buffer_len);
  return 1;
}

/* __index(buffer, key) */
static int luvbuffer__index (lua_State *L) {
  if (!lua_isnumber(L, 2)) { /* key should be a number */
    const char *value = lua_tolstring(L, 2, NULL);
    if (value[0] == 'l' && 0 == strncmp(value, "length", 7)) { /* ghetto deprecation! */
      BUFFER_UDATA(L)
      lua_pushnumber(L, buffer_len);
      return 1;
    }
    lua_getmetatable(L, 1); /*get userdata metatable */
    lua_pushvalue(L, 2);
    lua_rawget(L, -2); /*check environment table for field*/
    return 1;
  }

  BUFFER_UDATA(L)

  BUFFER_GETOFFSET(L, 2) /* sets index */

  /* skip first size_t length */
  lua_pushnumber(L, *((uint8_t*)(buffer + index - 1)));
  return 1;
}

int luvbuffer__pairs_aux(lua_State *L) {
  unsigned char *buffer = (unsigned char *)luaL_checkudata(L, -2, "luvbuffer");
  size_t buffer_len = *((size_t*)(buffer));

  size_t index = luaL_checknumber(L,-1);
  if( index >= buffer_len ) {
    return 0;
  }
        
  lua_pushinteger(L, index+1 );
  lua_pushnumber(L, *((uint8_t*)(buffer + index)));
  return 2;
}


static int luvbuffer__pairs (lua_State *L) {
  (void)luaL_checkudata(L,-1, "luvbuffer");
  lua_pushcfunction(L, luvbuffer__pairs_aux);
  lua_insert(L,-2);
  lua_pushinteger(L,0);
  return 3;
}

static int luvbuffer__concat (lua_State *L) {
  size_t new_size;
  unsigned char *new_buffer;
  size_t other_buffer_len;
  unsigned char *other_buffer;

  BUFFER_UDATA(L)

  int other_type = lua_type(L, 2);
  switch (other_type) {
    case LUA_TUSERDATA:
      other_buffer = (unsigned char *)luaL_checkudata(L, 2, "luvbuffer");
      other_buffer_len = *((size_t*)(other_buffer));
      other_buffer += sizeof(size_t);
      break;
    case LUA_TSTRING:
      other_buffer = (unsigned char *)lua_tolstring(L, 2, &other_buffer_len);
      break;
    default:
      goto out_err;
      break;
  }

  new_size = other_buffer_len + buffer_len;
  new_buffer = (unsigned char *)lua_resizeuserdata(L, 1, new_size);

  /* copy other_buffer to new userdata */
  memcpy(
     new_buffer + buffer_len /* lua_resizeuserdata copies only half of the data, so seek */
    ,other_buffer
    ,other_buffer_len
  );

  /* Set the type of the userdata as an luvbuffer instance */
  luaL_getmetatable(L, "luvbuffer");
  lua_setmetatable(L, -2);
  return 1;

out_err:
  return luaL_argerror(L, 2, "Must be of type 'String' or cBuffer");
}

/* __newindex(buffer, key, value) */
static int luvbuffer__newindex (lua_State *L) {
  size_t value_len;

  if (!lua_isnumber(L, 2)) { /* key should be a number */
    return luaL_argerror(L, 1, "We only support setting indices by type Number");
  }

  BUFFER_UDATA(L)

  BUFFER_GETOFFSET(L, 2) /* sets index */
  
  if (lua_isnumber(L, 3)) {
    value_len = (size_t)lua_tonumber(L, 3); /* using value_len here as value */
    if (value_len > 255) {
      return luaL_argerror(L, 3, "0 < Value < 255");
    }
    *((unsigned char *)(buffer + index - 1)) = value_len;
  } else if (lua_isstring(L, 3)) {
    const char *value = lua_tolstring(L, 3, &value_len);

    if (value_len > buffer_len - index - 1) {
      return luaL_argerror(L, 3, "Value is longer than Buffer Length");
    }
    memcpy(buffer + index - 1, value, value_len);
  } else {
    return luaL_argerror(L, 3, "Value is not of type 'String' or 'Number'");
  }
  return 1;
}


/******************************************************************************/

static const luaL_reg luvbuffer_m[] = {
   {"toString", luvbuffer_tostring}
  ,{"upUntil", luvbuffer_upuntil}
  ,{"inspect", luvbuffer_inspect}
  ,{"fill", luvbuffer_fill}

  /* binary helpers */
  ,{"readUInt8", luvbuffer__index} /* same as __index */
  ,{"readInt8", luvbuffer_readInt8}
  ,{"readUInt16BE", luvbuffer_readUInt16BE}
  ,{"readUInt16LE", luvbuffer_readUInt16LE}
  ,{"readUInt32BE", luvbuffer_readUInt32BE}
  ,{"readUInt32LE", luvbuffer_readUInt32LE}
  ,{"readInt32BE", luvbuffer_readInt32BE}
  ,{"readInt32LE", luvbuffer_readInt32LE}  
  ,{"writeUInt8", luvbuffer_writeUInt8}
  ,{"writeInt8", luvbuffer_writeInt8}
  ,{"writeUInt16BE", luvbuffer_writeUInt16BE}
  ,{"writeUInt16LE", luvbuffer_writeUInt16LE}
  ,{"writeUInt32BE", luvbuffer_writeUInt32BE}
  ,{"writeUInt32LE", luvbuffer_writeUInt32LE}
  ,{"writeInt32BE", luvbuffer_writeInt32BE}
  ,{"writeInt32LE", luvbuffer_writeInt32LE}  

   /* meta */
  ,{"__len", luvbuffer__len}
  ,{"__index", luvbuffer__index}
  ,{"__pairs", luvbuffer__pairs}
  ,{"__concat", luvbuffer__concat}
  ,{"__tostring", luvbuffer_tostring}
  ,{"__newindex", luvbuffer__newindex}
  ,{NULL, NULL}
};

static const luaL_reg luvbuffer_f[] = {
   {"new", luvbuffer_new}
  ,{"isBuffer", luvbuffer_isbuffer}
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

