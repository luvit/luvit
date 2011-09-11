#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "uv.h"

int main()
{
  int s=0;
  
  printf("\nUsing libuv version %d.%d\n", UV_VERSION_MAJOR, UV_VERSION_MINOR);

  lua_State *L = lua_open();

  // load the libs
  luaL_openlibs(L);

  //run a Lua scrip here
  luaL_dofile(L,"script.lua");

  printf("\nI am done with Lua in C++.\n");

  lua_close(L);

  return 0;
}
