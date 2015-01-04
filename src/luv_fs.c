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

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifndef _WIN32
#include <unistd.h>
#endif

#include "luv_fs.h"
#include "utils.h"
#include "luv_portability.h"

void luv_push_stats_table(lua_State* L, uv_statbuf_t* s) {
  lua_newtable(L);
  lua_pushinteger(L, s->st_dev);
  lua_setfield(L, -2, "dev");
  lua_pushinteger(L, s->st_ino);
  lua_setfield(L, -2, "ino");
  lua_pushinteger(L, s->st_mode);
  lua_setfield(L, -2, "mode");
  lua_pushinteger(L, s->st_nlink);
  lua_setfield(L, -2, "nlink");
  lua_pushinteger(L, s->st_uid);
  lua_setfield(L, -2, "uid");
  lua_pushinteger(L, s->st_gid);
  lua_setfield(L, -2, "gid");
  lua_pushinteger(L, s->st_rdev);
  lua_setfield(L, -2, "rdev");
  lua_pushinteger(L, s->st_size);
  lua_setfield(L, -2, "size");
  lua_pushinteger(L, s->st_atime);
  lua_setfield(L, -2, "atime");
  lua_pushinteger(L, s->st_mtime);
  lua_setfield(L, -2, "mtime");
  lua_pushinteger(L, s->st_ctime);
  lua_setfield(L, -2, "ctime");
  lua_pushboolean(L, S_ISREG(s->st_mode));
  lua_setfield(L, -2, "is_file");
  lua_pushboolean(L, S_ISDIR(s->st_mode));
  lua_setfield(L, -2, "is_directory");
  lua_pushboolean(L, S_ISCHR(s->st_mode));
  lua_setfield(L, -2, "is_character_device");
  lua_pushboolean(L, S_ISBLK(s->st_mode));
  lua_setfield(L, -2, "is_block_device");
  lua_pushboolean(L, S_ISFIFO(s->st_mode));
  lua_setfield(L, -2, "is_fifo");
  lua_pushboolean(L, S_ISLNK(s->st_mode));
  lua_setfield(L, -2, "is_symbolic_link");
  lua_pushboolean(L, S_ISSOCK(s->st_mode));
  lua_setfield(L, -2, "is_socket");
#if defined(__unix__) || defined(__POSIX__)
  lua_pushinteger(L, s->st_blksize);
  lua_setfield(L, -2, "blksize");
  lua_pushinteger(L, s->st_blocks);
  lua_setfield(L, -2, "blocks");
#endif
}

int luv_string_to_flags(lua_State* L, const char* string) {
  if (strcmp(string, "r") == 0) return O_RDONLY;
  if (strcmp(string, "r+") == 0) return O_RDWR;
  if (strcmp(string, "w") == 0) return O_CREAT | O_TRUNC | O_WRONLY;
  if (strcmp(string, "w+") == 0) return O_CREAT | O_TRUNC | O_RDWR;
  if (strcmp(string, "a") == 0) return O_APPEND | O_CREAT | O_WRONLY;
  if (strcmp(string, "a+") == 0) return O_APPEND | O_CREAT | O_RDWR;
#ifndef _WIN32
  if (strcmp(string, "rs") == 0) return O_RDONLY | O_SYNC;
  if (strcmp(string, "rs+") == 0) return O_RDWR | O_SYNC;
#endif
  return luaL_error(L, "Unknown file open flag'%s'", string);
}

int luv_process_fs_result(lua_State* L, uv_fs_t* req) {
  luv_fs_ref_t* ref = req->data;

  int argc = 0;
  if (req->result == -1) {
    uv_err_t err;
    memset(&err, 0, sizeof err);
    err.code = (uv_err_code)req->errorno;
    luv_push_async_error(L, err, "after_fs", req->path);
  } else {
    lua_pushnil(L);
    switch (req->fs_type) {

      case UV_FS_CLOSE:
      case UV_FS_RENAME:
      case UV_FS_UNLINK:
      case UV_FS_RMDIR:
      case UV_FS_MKDIR:
      case UV_FS_FTRUNCATE:
      case UV_FS_FSYNC:
      case UV_FS_FDATASYNC:
      case UV_FS_LINK:
      case UV_FS_SYMLINK:
      case UV_FS_CHMOD:
      case UV_FS_FCHMOD:
      case UV_FS_CHOWN:
      case UV_FS_FCHOWN:
      case UV_FS_UTIME:
      case UV_FS_FUTIME:
        argc = 0;
        break;

      case UV_FS_OPEN:
      case UV_FS_SENDFILE:
      case UV_FS_WRITE:
        argc = 1;
        lua_pushinteger(L, req->result);
        break;

      case UV_FS_STAT:
      case UV_FS_LSTAT:
      case UV_FS_FSTAT:
        argc = 1;
        luv_push_stats_table(L, (uv_statbuf_t*)req->ptr);
        break;

      case UV_FS_READLINK:
        argc = 1;
        lua_pushstring(L, (char*)req->ptr);
        break;

      case UV_FS_READ:
        argc = 2;
        lua_pushlstring(L, ref->buf, req->result);
        lua_pushinteger(L, req->result);
        free(ref->buf);
        break;

      case UV_FS_READDIR:
        {
          int i;
          char* namebuf = (char*)req->ptr;
          int nnames = req->result;

          argc = 1;
          lua_createtable(L, nnames, 0);
          for (i = 0; i < nnames; i++) {
            lua_pushstring(L, namebuf);
            lua_rawseti(L, -2, i + 1);
            namebuf += strlen(namebuf);
            assert(*namebuf == '\0');
            namebuf += 1;
          }
        }
        break;

      default:
        assert(0 && "Unhandled eio response");
    }

  }

  return argc;

}

void luv_after_fs(uv_fs_t* req) {
  luv_fs_ref_t* ref = req->data;
  lua_State *L = ref->L;
  int argc;

  luv_io_ctx_callback_rawgeti(L, &ref->cbs);
  luv_io_ctx_unref(L, &ref->cbs);

  argc = luv_process_fs_result(L, req);

  luv_acall(L, argc + 1, 0, "fs_after");

  uv_fs_req_cleanup(req);
  free(ref); /* We're done with the ref object, free it */
}

static luv_fs_ref_t* luv_fs_ref_alloc(lua_State* L) {
  luv_fs_ref_t* ref = malloc(sizeof(luv_fs_ref_t));
  ref->L = L;
  ref->fs_req.data = ref;
  return ref;
}

/* Utility for storing the callback in the fs_req token */
uv_fs_t* luv_fs_store_callback(lua_State* L, int index) {
  luv_fs_ref_t* ref = luv_fs_ref_alloc(L);
  luv_io_ctx_init(&ref->cbs);
  luv_io_ctx_callback_add(L, &ref->cbs, index);
  return &ref->fs_req;
}

#define FS_CALL(func, cb_index, path, ...)                                    \
  do {                                                                        \
    uv_err_t err;                                                             \
    int argc;                                                                 \
    if (lua_isfunction(L, cb_index)) {                                        \
      if (uv_fs_##func(luv_get_loop(L), req, __VA_ARGS__, luv_after_fs)) {  \
        err = uv_last_error(luv_get_loop(L));                                 \
        luv_push_async_error(L, err, #func, path);                            \
        uv_fs_req_cleanup(req);                                                   \
        free(req->data);                                                      \
        return lua_error(L);                                                  \
      }                                                                       \
      return 0;                                                               \
    }                                                                         \
    if (uv_fs_##func(luv_get_loop(L), req, __VA_ARGS__, NULL) < 0) {        \
      err = uv_last_error(luv_get_loop(L));                                 \
      luv_push_async_error(L, err, #func, path);                              \
      uv_fs_req_cleanup(req);                                                 \
      free(req->data);                                                        \
      return lua_error(L);                                                    \
    }                                                                         \
    argc = luv_process_fs_result(L, req);                                 \
    lua_remove(L, -argc - 1);                                                 \
    uv_fs_req_cleanup(req);                                                   \
    free(req->data);                                                          \
    return argc;                                                              \
  } while (0)


int luv_fs_open(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  int flags = luv_string_to_flags(L, luaL_checkstring(L, 2));
  int mode = luaL_checkint(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);
  FS_CALL(open, 4, path, path, flags, mode);
}

int luv_fs_close(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(close, 2, NULL, file);
}

int luv_fs_read(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  int offset = -1;
  int length;
  uv_fs_t* req;
  void* buf;
  if (!lua_isnil(L, 2)) {
    offset = luaL_checkint(L, 2);
  }
  length = luaL_checkint(L, 3);
  req = luv_fs_store_callback(L, 4);
  buf = malloc(length);
  ((luv_fs_ref_t*)req->data)->buf = buf;
  FS_CALL(read, 4, NULL, file, buf, length, offset);
}

int luv_fs_write(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  off_t offset = luaL_checkint(L, 2);
  size_t length;
  uv_fs_t* req;
  void* chunk = (void*)luaL_checklstring(L, 3, &length);
  luv_fs_ref_t* ref = luv_fs_ref_alloc(L);
  luv_io_ctx_init(&ref->cbs);
  luv_io_ctx_add(L, &ref->cbs, 3);
  luv_io_ctx_callback_add(L, &ref->cbs, 4);
  req = &ref->fs_req;
  FS_CALL(write, 4, NULL, file, chunk, length, offset);
}

int luv_fs_unlink(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(unlink, 2, path, path);
}

int luv_fs_mkdir(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  int mode = strtoul(luaL_checkstring(L, 2), NULL, 8);
  uv_fs_t* req = luv_fs_store_callback(L, 3);
  FS_CALL(mkdir, 3, path, path, mode);
}

int luv_fs_rmdir(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(rmdir, 2, path, path);
}

int luv_fs_readdir(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(readdir, 2, path, path, 0);
}


int luv_fs_stat(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(stat, 2, path, path);
}

int luv_fs_fstat(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(fstat, 2, NULL, file);
}

int luv_fs_rename(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  const char* new_path = luaL_checkstring(L, 2);
  uv_fs_t* req = luv_fs_store_callback(L, 3);
  FS_CALL(rename, 3, path, path, new_path);
}

int luv_fs_fsync(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(fsync, 2, NULL, file);
}

int luv_fs_fdatasync(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(fdatasync, 2, NULL, file);
}

int luv_fs_ftruncate(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  off_t offset = luaL_checkint(L, 2);
  uv_fs_t* req = luv_fs_store_callback(L, 3);
  FS_CALL(ftruncate, 3, NULL, file, offset);
}

int luv_fs_sendfile(lua_State* L) {
  uv_file out_fd = luaL_checkint(L, 1);
  uv_file in_fd = luaL_checkint(L, 2);
  off_t in_offset = luaL_checkint(L, 3);
  size_t length = luaL_checkint(L, 4);
  uv_fs_t* req = luv_fs_store_callback(L, 5);
  FS_CALL(sendfile, 5, NULL, out_fd, in_fd, in_offset, length);
}

int luv_fs_chmod(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  int mode = strtoul(luaL_checkstring(L, 2), NULL, 8);
  uv_fs_t* req = luv_fs_store_callback(L, 3);
  FS_CALL(chmod, 3, path, path, mode);
}

int luv_fs_utime(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  double atime = luaL_checknumber(L, 2);
  double mtime = luaL_checknumber(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);
  FS_CALL(utime, 4, path, path, atime, mtime);
}

int luv_fs_futime(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  double atime = luaL_checknumber(L, 2);
  double mtime = luaL_checknumber(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);
  FS_CALL(futime, 4, NULL, file, atime, mtime);
}

int luv_fs_lstat(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(lstat, 2, path, path);
}

int luv_fs_link(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  const char* new_path = luaL_checkstring(L, 2);
  uv_fs_t* req = luv_fs_store_callback(L, 3);
  FS_CALL(link, 3, path, path, new_path);
}

int luv_fs_symlink(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  const char* new_path = luaL_checkstring(L, 2);
  int flags = luv_string_to_flags(L, luaL_checkstring(L, 3));
  uv_fs_t* req = luv_fs_store_callback(L, 4);
  FS_CALL(symlink, 4, new_path, path, new_path, flags);
}

int luv_fs_readlink(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);
  FS_CALL(readlink, 2, path, path);
}

int luv_fs_fchmod(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  int mode = strtoul(luaL_checkstring(L, 2), NULL, 8);
  uv_fs_t* req = luv_fs_store_callback(L, 3);
  FS_CALL(fchmod, 3, NULL, file, mode);
}

int luv_fs_chown(lua_State* L) {
  const char* path = luaL_checkstring(L, 1);
  int uid = luaL_checkint(L, 2);
  int gid = luaL_checkint(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);
  FS_CALL(chown, 4, path, path, uid, gid);
}

int luv_fs_fchown(lua_State* L) {
  uv_file file = luaL_checkint(L, 1);
  int uid = luaL_checkint(L, 2);
  int gid = luaL_checkint(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);
  FS_CALL(fchown, 4, NULL, file, uid, gid);
}

