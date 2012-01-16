/*
 *  Copyright 2012 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <limits.h> /* PATH_MAX */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "luvit.h"
#include "uv.h"
#include "luv.h"

const void *suck_in_luvit(void);

int main(int argc, char *argv[])
{
  lua_State *L;
  uv_loop_t *loop;

  suck_in_luvit();

  L = luaL_newstate();
  if (L == NULL) {
    fprintf(stderr, "luaL_newstate has failed\n");
    return 1;
  }

  luaL_openlibs(L);

  loop = uv_default_loop();

  if (luvit_init(L, loop, argc, argv)) {
    fprintf(stderr, "luvit_init has failed\n");
    return 1;
  }

  // Run the main lua script
  if (luvit_run(L)) {
    printf("%s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
    lua_close(L);
    return -1;
  }

  lua_close(L);
  return 0;
}
