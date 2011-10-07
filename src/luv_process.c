#include <stdlib.h>
#include <assert.h>

#include "luv_process.h"

/* Initializes uv_process_t and starts the process. */
//int uv_spawn(uv_loop_t*, uv_process_t*, uv_process_options_t options);
int luv_spawn(lua_State* L) {
  return luaL_error(L, "TODO: Implement lua_spawn");
}

/*
 * Kills the process with the specified signal. The user must still
 * call uv_close on the process.
 */
//int uv_process_kill(uv_process_t*, int signum);
int luv_process_kill(lua_State* L) {
  return luaL_error(L, "TODO: Implement lua_process_kill");
}

