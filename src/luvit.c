#include <string.h>
#include <assert.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "luvit.h"
#include "uv.h"
#include "utils.h"
#include "luv.h"
#include "lhttp_parser.h"
#include "lenv.h"

int main(int argc, char *argv[])
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
  // Register env
  lua_pushcfunction(L, luaopen_env);
  lua_setfield(L, -2, "env");

  // We're done with preload, put it away
  lua_pop(L, 1);

  // Get argv
  lua_createtable (L, argc, 0);
  int index;
  for (index = 0; index < argc; index++) {
    lua_pushstring (L, argv[index]);
    lua_rawseti(L, -2, index);
  }
  lua_setglobal(L, "argv");

  assert(lua_pushthread(L) == 1);
  lua_setglobal(L, "main_thread");

  // Run the main lua script
  if (luaL_dostring(L, "assert(require('luvit'))")) {
    printf("%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
    return -1;
  }

  lua_close(L);
  return 0;
}
