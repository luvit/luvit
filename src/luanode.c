#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "luv.h"
#include "lhttp_parser.h"

int main()
{
  lua_State *L = lua_open();
  luaL_openlibs(L);
  luaopen_uv(L);
  luaopen_http_parser(L);

  if (luaL_dofile(L, "lib/main.lua"))
  {
    printf("%s\n", lua_tostring(L, -1));
  }

  return 0;
}
