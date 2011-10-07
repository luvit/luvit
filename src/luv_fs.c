#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>


#include "luv_fs.h"

void luv_push_stats_table(lua_State* L, struct stat* s) {
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
#ifdef __POSIX__
  lua_pushinteger(L, s->st_blksize);
  lua_setfield(L, -2, "blksize");
  lua_pushinteger(L, s->st_blocks);
  lua_setfield(L, -2, "blocks");
#endif
  lua_pushinteger(L, s->st_atime);
  lua_setfield(L, -2, "atime");
  lua_pushinteger(L, s->st_mtime);
  lua_setfield(L, -2, "mtime");
  lua_pushinteger(L, s->st_ctime);
  lua_setfield(L, -2, "ctime");
}

// Pushes a error object onto the stack
void luv_fs_error(lua_State* L,
                  int errorno,
                  const char *syscall,
                  const char *msg,
                  const char *path) {

  if (!msg || !msg[0]) {
    msg = errno_message(errorno);
  }

  lua_newtable(L);
  if (path) {
    lua_pushfstring(L, "%s, %s '%s'", errno_string(errorno), msg, path);
  } else {
    lua_pushfstring(L, "%s, %s", errno_string(errorno), msg);
  }
  lua_setfield(L, -2, "message");
  lua_pushstring(L, errno_string(errorno));
  lua_setfield(L, -2, "code");
  if (path) {
    lua_pushstring(L, path);
    lua_setfield(L, -2, "path");
  }
}

int luv_string_to_flags(lua_State* L, const char* string) {
  if (strcmp(string, "r") == 0) return O_RDONLY;
  if (strcmp(string, "r+") == 0) return O_RDWR;
  if (strcmp(string, "w") == 0) return O_CREAT | O_TRUNC | O_WRONLY;
  if (strcmp(string, "w+") == 0) return O_CREAT | O_TRUNC | O_RDWR;
  if (strcmp(string, "a") == 0) return O_APPEND | O_CREAT | O_WRONLY;
  if (strcmp(string, "a+") == 0) return O_APPEND | O_CREAT | O_RDWR;
  return luaL_error(L, "Unknown file open flag'%s'", string);
}

void luv_fs_after(uv_fs_t* req) {
  luv_fs_ref_t* ref = req->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  luaL_unref(L, LUA_REGISTRYINDEX, ref->r);

  int argc = 0;
  if (req->result == -1) {
    luv_fs_error(L, req->errorno, NULL, NULL, req->path);
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
        luv_push_stats_table(L, (struct stat*)req->ptr);
        break;

      case UV_FS_READLINK:
        argc = 1;
        lua_pushstring(L, (char*)req->ptr);
        break;

      case UV_FS_READ:
        argc = 1;
        lua_pushlstring(L, ref->buf, req->result);
        free(ref->buf);
        break;

      case UV_FS_READDIR:
        {
          char* namebuf = (char*)req->ptr;
          int nnames = req->result;

          argc = 1;
          lua_createtable(L, nnames, 0);
          int i;
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

  lua_call(L, argc + 1, 0);

  uv_fs_req_cleanup(req);
  free(ref);// We're done with the ref object, free it
  assert(lua_gettop(L) == before);
}

// Utility for storing the callback in the fs_req token
uv_fs_t* luv_fs_store_callback(lua_State* L, int index) {
  int before = lua_gettop(L);

  luaL_checktype(L, index, LUA_TFUNCTION);

  // Get the main thread
  lua_getglobal(L, "main_thread");
  lua_State* L1 = lua_tothread(L, -1);
  lua_pop(L, 1);

  luv_fs_ref_t* ref = malloc(sizeof(luv_fs_ref_t));
  ref->L = L1;
  lua_pushvalue(L, index); // Store the callback
  lua_xmove(L, L1, 1); // Move to the main_thread
  ref->r = luaL_ref(L1, LUA_REGISTRYINDEX);
  ref->fs_req.data = ref;
  assert(lua_gettop(L) == before);
  return &ref->fs_req;
}

int luv_fs_open(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  int flags = luv_string_to_flags(L, luaL_checkstring(L, 2));
  int mode = strtoul(luaL_checkstring(L, 3), NULL, 8);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  if (uv_fs_open(uv_default_loop(), req, path, flags, mode, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_open: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_close(lua_State* L) {
  int before = lua_gettop(L);
  int fd = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_close(uv_default_loop(), req, (uv_file)fd, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_close: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_read(lua_State* L) {
  int before = lua_gettop(L);
  int fd = luaL_checkint(L, 1);
  int offset = luaL_checkint(L, 2);
  int length = luaL_checkint(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  void* buf = malloc(length);
  ((luv_fs_ref_t*)req->data)->buf = buf;

  if (uv_fs_read(uv_default_loop(), req, (uv_file)fd, buf, length, offset, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_read: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_write(lua_State* L) {
  int before = lua_gettop(L);
  int fd = luaL_checkint(L, 1);
  off_t offset = luaL_checkint(L, 2);
  size_t length;
  const char* chunk = luaL_checklstring(L, 3, &length);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  if (uv_fs_write(uv_default_loop(), req, (uv_file)fd, (void*)chunk, length, offset, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_write: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_unlink(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_unlink(uv_default_loop(), req, path, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_unlink: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_mkdir(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  int mode = luaL_checkint(L, 2);
  uv_fs_t* req = luv_fs_store_callback(L, 3);

  if (uv_fs_mkdir(uv_default_loop(), req, path, mode, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_mkdir: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_rmdir(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_rmdir(uv_default_loop(), req, path, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_rmdir: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_readdir(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_readdir(uv_default_loop(), req, path, 0, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_readdir: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}


int luv_fs_stat(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_stat(uv_default_loop(), req, path, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_stat: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_fstat(lua_State* L) {
  int before = lua_gettop(L);
  uv_file file = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_fstat(uv_default_loop(), req, file, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_fstat: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_rename(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  const char* new_path = luaL_checkstring(L, 2);
  uv_fs_t* req = luv_fs_store_callback(L, 3);

  if (uv_fs_rename(uv_default_loop(), req, path, new_path, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_rename: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_fsync(lua_State* L) {
  int before = lua_gettop(L);
  uv_file file = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_fsync(uv_default_loop(), req, file, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_fsync: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}


int luv_fs_fdatasync(lua_State* L) {
  int before = lua_gettop(L);
  uv_file file = luaL_checkint(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_fdatasync(uv_default_loop(), req, file, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_fdatasync: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_ftruncate(lua_State* L) {
  int before = lua_gettop(L);
  uv_file file = luaL_checkint(L, 1);
  off_t offset = luaL_checkint(L, 2);
  uv_fs_t* req = luv_fs_store_callback(L, 3);

  if (uv_fs_ftruncate(uv_default_loop(), req, file, offset, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_ftruncate: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_sendfile(lua_State* L) {
  int before = lua_gettop(L);
  uv_file out_fd = luaL_checkint(L, 1);
  uv_file in_fd = luaL_checkint(L, 2);
  off_t in_offset = luaL_checkint(L, 3);
  size_t length = luaL_checkint(L, 4);
  uv_fs_t* req = luv_fs_store_callback(L, 5);

  if (uv_fs_sendfile(uv_default_loop(), req, out_fd, in_fd, in_offset, length, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_sendfile: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_chmod(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  int mode = strtoul(luaL_checkstring(L, 2), NULL, 8);
  uv_fs_t* req = luv_fs_store_callback(L, 3);

  if (uv_fs_chmod(uv_default_loop(), req, path, mode, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_chmod: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_utime(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  double atime = luaL_checknumber(L, 2);
  double mtime = luaL_checknumber(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  if (uv_fs_utime(uv_default_loop(), req, path, atime, mtime, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_utime: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_futime(lua_State* L) {
  int before = lua_gettop(L);
  uv_file file = luaL_checkint(L, 1);
  double atime = luaL_checknumber(L, 2);
  double mtime = luaL_checknumber(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  if (uv_fs_futime(uv_default_loop(), req, file, atime, mtime, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_futime: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_lstat(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_lstat(uv_default_loop(), req, path, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_lstat: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_link(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  const char* new_path = luaL_checkstring(L, 2);
  uv_fs_t* req = luv_fs_store_callback(L, 3);

  if (uv_fs_link(uv_default_loop(), req, path, new_path, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_link: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_symlink(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  const char* new_path = luaL_checkstring(L, 2);
  int flags  = luaL_checkint(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  if (uv_fs_symlink(uv_default_loop(), req, path, new_path, flags, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_symlink: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_readlink(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  uv_fs_t* req = luv_fs_store_callback(L, 2);

  if (uv_fs_readlink(uv_default_loop(), req, path, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_readlink: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_fchmod(lua_State* L) {
  int before = lua_gettop(L);
  uv_file file = luaL_checkint(L, 1);
  int mode = strtoul(luaL_checkstring(L, 2), NULL, 8);
  uv_fs_t* req = luv_fs_store_callback(L, 3);

  if (uv_fs_fchmod(uv_default_loop(), req, file, mode, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_fchmod: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_chown(lua_State* L) {
  int before = lua_gettop(L);
  const char* path = luaL_checkstring(L, 1);
  int uid = luaL_checkint(L, 2);
  int gid = luaL_checkint(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  if (uv_fs_chown(uv_default_loop(), req, path, uid, gid, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_chown: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_fchown(lua_State* L) {
  int before = lua_gettop(L);
  uv_file file = luaL_checkint(L, 1);
  int uid = luaL_checkint(L, 2);
  int gid = luaL_checkint(L, 3);
  uv_fs_t* req = luv_fs_store_callback(L, 4);

  if (uv_fs_fchown(uv_default_loop(), req, file, uid, gid, luv_fs_after)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "fs_fchown: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

