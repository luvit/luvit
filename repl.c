#include <stdio.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

/* the Lua interpreter */
lua_State* L;

int main ( int argc, char *argv[] )
{
  /* initialize Lua */
  L = lua_open();

  /* load various Lua libraries */
/*  lua_baselibopen(L);*/
  luaopen_table(L);
  luaopen_io(L);
  luaopen_string(L);
  luaopen_math(L);
    
  /* cleanup Lua */
  lua_close(L);

  return 0;
}

