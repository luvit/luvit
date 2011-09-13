
#include "lhttp_parser.h"

/*static int http_parser_sin (lua_State *L) {*/
/*  lua_pushnumber(L, sin(luaL_checknumber(L, 1)));*/
/*  return 1;*/
/*}*/

static const luaL_reg http_parserlib[] = {
/*  {"sin", http_parser_sin},*/
  {NULL, NULL}
};

/*
** Open uv library
*/
LUALIB_API int luaopen_http_parser (lua_State *L) {
  luaL_register(L, "http_parser", http_parserlib);
  return 1;
}

