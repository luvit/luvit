#ifndef LUV_FS_WATCHER
#define LUV_FS_WATCHER

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_handle.h"

void luv_on_fs_event(uv_fs_event_t* handle, const char* filename, int events, int status);

int luv_new_fs_watcher (lua_State* L);

#endif
