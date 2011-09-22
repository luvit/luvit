#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "luv.h"
#include "lhttp_parser.h"

int main()
{
  lua_State *L = lua_open();
  luaL_openlibs(L);

  // Pull up the preload table
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_remove(L, -2);

  // Register http_parser
  lua_pushcfunction(L, luaopen_http_parser);
  lua_setfield(L, -2, "http_parser");
  // Register uv
  lua_pushcfunction(L, luaopen_uv);
  lua_setfield(L, -2, "uv");

  // We're done with preload, put it away
  lua_pop(L, 1);

  // Run the main lua script
  if (luaL_dofile(L, "lib/main.lua"))
  {
    printf("%s\n", lua_tostring(L, -1));
  }

  return 0;
}
