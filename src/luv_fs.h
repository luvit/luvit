#ifndef LUV_FS
#define LUV_FS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"

void luv_fs_error(lua_State* L, int errorno, const char *syscall, const char *msg, const char *path);

// Utility to convert string flags to proper int flags
int luv_string_to_flags(lua_State* L, const char* string);

// Common callback for all luv_fs_* async functions
void luv_fs_after(uv_fs_t* req);

// Utility for storing the callback in the fs_req token
uv_fs_t* luv_fs_store_callback(lua_State* L, int index);

// Wrapped functions exposed to lua
int luv_fs_open(lua_State* L);
int luv_fs_close(lua_State* L);
int luv_fs_read(lua_State* L);
int luv_fs_write(lua_State* L);
int luv_fs_unlink(lua_State* L);
int luv_fs_mkdir(lua_State* L);
int luv_fs_rmdir(lua_State* L);

typedef struct {
  lua_State* L;
  int r;
  uv_fs_t fs_req;
  void* buf;
} luv_fs_ref_t;

#endif
