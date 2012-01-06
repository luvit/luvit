#include "lyajl.h"
#include "yajl/yajl_parse.h"
#include "yajl/yajl_version.h"

static const luaL_reg lyajl_f[] = {
  {NULL, NULL}
};

LUALIB_API int luaopen_yajl (lua_State *L) {
  // Create a new exports table
  lua_newtable (L);
  // Put our functions on it
  luaL_register(L, NULL, lyajl_f);
  // Stick on version info
  lua_pushnumber(L, YAJL_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, YAJL_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");
  lua_pushnumber(L, YAJL_MICRO);
  lua_setfield(L, -2, "VERSION_MICRO");

  // Return the new module
  return 1;
}
