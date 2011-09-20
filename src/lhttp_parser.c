#include "lhttp_parser.h"
#include "http_parser.h"


// Takes as arguments a string for type and a table for event callbacks
static int http_parser_new (lua_State *L) {

  const char *type = luaL_checkstring(L, 1);
  luaL_argcheck(L, (0 == strcasecmp(type, "request")) || (0 == strcasecmp(type, "response")), 1, "type must be 'request' or 'response'");
  luaL_checktype(L, 2, LUA_TTABLE);

  // TODO: make userdata instance and return it instead of this string
  lua_pushstring(L, type);
  return 1;
}

static const luaL_reg http_parserlib[] = {
  {"new", http_parser_new},
  {NULL, NULL}
};

/*
** Open uv library
*/
LUALIB_API int luaopen_http_parser (lua_State *L) {
  luaL_register(L, "http_parser", http_parserlib);

  lua_pushnumber(L, HTTP_PARSER_VERSION_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, HTTP_PARSER_VERSION_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");
  
  return 1;
}

