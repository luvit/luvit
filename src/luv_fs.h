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

#ifndef LUV_FS
#define LUV_FS

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"

void luv_push_stats_table(lua_State* L, struct stat* s);

void luv_fs_error(lua_State* L, int errorno, const char *syscall, const char *msg, const char *path);

/* Utility to convert string flags to proper int flags */
int luv_string_to_flags(lua_State* L, const char* string);

/* Utility for storing the callback in the fs_req token */
uv_fs_t* luv_fs_store_callback(lua_State* L, int index);

/* Wrapped functions exposed to lua */
int luv_fs_open(lua_State* L);
int luv_fs_close(lua_State* L);
int luv_fs_read(lua_State* L);
int luv_fs_write(lua_State* L);
int luv_fs_unlink(lua_State* L);
int luv_fs_mkdir(lua_State* L);
int luv_fs_rmdir(lua_State* L);
int luv_fs_readdir(lua_State* L);
int luv_fs_stat(lua_State* L);
int luv_fs_fstat(lua_State* L);
int luv_fs_rename(lua_State* L);
int luv_fs_fsync(lua_State* L);
int luv_fs_fdatasync(lua_State* L);
int luv_fs_ftruncate(lua_State* L);
int luv_fs_sendfile(lua_State* L);
int luv_fs_chmod(lua_State* L);
int luv_fs_utime(lua_State* L);
int luv_fs_futime(lua_State* L);
int luv_fs_lstat(lua_State* L);
int luv_fs_link(lua_State* L);
int luv_fs_symlink(lua_State* L);
int luv_fs_readlink(lua_State* L);
int luv_fs_fchmod(lua_State* L);
int luv_fs_chown(lua_State* L);
int luv_fs_fchown(lua_State* L);

typedef struct {
  lua_State* L;
  int rcb; /* callback ref */
  int rstr; /* string ref */
  uv_fs_t fs_req;
  void* buf;
} luv_fs_ref_t;

#endif
