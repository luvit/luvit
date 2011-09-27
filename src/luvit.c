#include <string.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "utils.h"
#include "luv.h"
#include "lhttp_parser.h"

int main()
{
  lua_State *L = lua_open();

/*  luaL_openlibs(L);*/

  // Preload a couple libs  
  lua_pushcfunction(L, luaopen_package);
  lua_call(L, 0, 0);
  lua_pushcfunction(L, luaopen_base);
  lua_call(L, 0, 0);
  lua_pushcfunction(L, luaopen_string);
  lua_call(L, 0, 0);
  lua_pushcfunction(L, luaopen_table);
  lua_call(L, 0, 0);
  lua_pushcfunction(L, luaopen_math);
  lua_call(L, 0, 0);
  lua_pushcfunction(L, luaopen_bit);
  lua_call(L, 0, 0);


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
  // Register some of the builtins
  lua_pushcfunction(L, luaopen_debug);
  lua_setfield(L, -2, "debug");
  lua_pushcfunction(L, luaopen_jit);
  lua_setfield(L, -2, "jit");
  lua_pushcfunction(L, luaopen_ffi);
  lua_setfield(L, -2, "ffi");
  // We're done with preload, put it away
  lua_pop(L, 1);

  // Run the main lua script
  if (luaL_dofile(L, "src/luvit.lua"))
  {
    printf("%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
  }
/*
  char buff[256];
  int error;
  
  const char* prompt = "luanode> ";
  printf("%s", prompt);
  while (fgets(buff, sizeof(buff), stdin) != NULL) {
    error = luaL_loadbuffer(L, buff, strlen(buff), "line") || lua_pcall(L, 0, 0, 0);
    if (error) {
      fprintf(stderr, "%s\n", lua_tostring(L, -1));
      lua_pop(L, 1); // pop error message from the stack
    }
    printf("%s", prompt);
  }
  printf("\n");
*/

  lua_close(L);
  return 0;
}
