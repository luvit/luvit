#include <math.h>
#include <string.h>
#include "vector.h"

#define PI 3.14159265

/* Define a simple C struct to test the C/Lua interaction */
typedef struct {
  double x;
  double y;
} Vector;

/* Constructor function for Vector instances */
static int new_vector(lua_State* L) {
  double x = luaL_checknumber(L, 1);
  double y = luaL_checknumber(L, 2);
  Vector* vector = (Vector*)lua_newuserdata(L, sizeof(Vector));
  vector->x = x;
  vector->y = y;
  
  luaL_getmetatable(L, "vector");
  lua_setmetatable(L, -2);

  return 1;
}

static int vector_index(lua_State* L) {
  Vector* vector = (Vector*)luaL_checkudata(L, 1, "vector");
  const char* name = luaL_checkstring(L, 2);
  if (strcmp(name, "x") == 0) {
    lua_pushnumber(L, vector->x);
  } else if (strcmp(name, "y") == 0) {
    lua_pushnumber(L, vector->y);
  } else if (strcmp(name, "angle") == 0) {
    lua_pushnumber(L, atan2 (vector->y, vector->x) * 180 / PI);
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int vector_newindex(lua_State* L) {
  Vector* vector = (Vector*)luaL_checkudata(L, 1, "vector");
  const char* name = luaL_checkstring(L, 2);
  double value = luaL_checknumber(L, 3);
  if (strcmp(name, "x") == 0) {
    vector->x = value;
  } else if (strcmp(name, "y") == 0) {
    vector->y = value;
  } else {
    return luaL_error(L, "Can only set x and y properties on Vector instances");
  }
  return 0;
}

static const luaL_reg vector_f[] = {
  {"new", new_vector},
  {NULL, NULL}
};

static const luaL_reg vector_m[] = {
  {"__index", vector_index},
  {"__newindex", vector_newindex},
  {NULL, NULL}
};

LUALIB_API int luaopen_vector (lua_State *L) {

  /* Create a metatable for the vector type */
  luaL_newmetatable(L, "vector");
  luaL_register(L, NULL, vector_m);
  lua_pop(L, 1);

  lua_newtable (L);
  luaL_register(L, NULL, vector_f);
  return 1;
}
