#include <stdlib.h>
#include <assert.h>

#include "luv_fs_watcher.h"
#include "luv_fs.h"

void luv_on_fs_event(uv_fs_event_t* handle, const char* filename, int events, int status) {

  // load the lua state and the userdata
  luv_ref_t* ref = handle->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  lua_pushinteger(L, status);

  switch (events) {
    case UV_RENAME: lua_pushstring(L, "rename"); break;
    case UV_CHANGE: lua_pushstring(L, "change"); break;
    default: lua_pushnil(L); break;
  }

  if (filename) {
    lua_pushstring(L, filename);
  } else {
    lua_pushnil(L);
  }

  luv_emit_event(L, "change", 3);
  lua_pop(L, 1); // remove the userdata
  assert(lua_gettop(L) == before);

}


int luv_new_fs_watcher (lua_State* L) {
  int before = lua_gettop(L);
  const char* filename = luaL_checkstring(L, 1);
  
  uv_fs_event_t* handle = (uv_fs_event_t*)lua_newuserdata(L, sizeof(uv_fs_event_t));

  uv_fs_event_init(uv_default_loop(), handle, filename, luv_on_fs_event);
    
  // Set metatable for type
  luaL_getmetatable(L, "luv_fs_watcher");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // Store a reference to the userdata in the handle
  luv_ref_t* ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  assert(lua_gettop(L) == before + 1);
  // return the userdata
  return 1;
}


