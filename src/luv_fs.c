#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "luv_fs.h"

void luv_fs_error(lua_State* L,
                  int errorno,
                  const char *syscall,
                  const char *msg,
                  const char *path) {

  if (!msg || !msg[0]) {
    msg = errno_message(errorno);
  }

  if (path) {
    error(L, "%s, %s '%s'", errno_string(errorno), msg, path);
  } else {
    error(L, "%s, %s", errno_string(errorno), msg);
  }
}

int luv_string_to_flags(lua_State* L, const char* string) {
  if (strcmp(string, "r") == 0) return O_RDONLY;
  if (strcmp(string, "r+") == 0) return O_RDWR;
  if (strcmp(string, "w") == 0) return O_CREAT | O_TRUNC | O_WRONLY;
  if (strcmp(string, "w+") == 0) return O_CREAT | O_TRUNC | O_RDWR;
  if (strcmp(string, "a") == 0) return O_APPEND | O_CREAT | O_WRONLY;
  if (strcmp(string, "a+") == 0) return O_APPEND | O_CREAT | O_RDWR;
  error(L, "Unknown file open flag'%s'", string);
  return 0;
}

void luv_fs_after(uv_fs_t* req) {
  luv_fs_ref_t* ref = req->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  luaL_unref(L, LUA_REGISTRYINDEX, ref->r);

  if (req->result == -1) {
    lua_pop(L, 1);
    luv_fs_error(L, req->errorno, NULL, NULL, req->path);
  } else {
    int argc = 0;
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
        {
/*          NODE_STAT_STRUCT *s = reinterpret_cast<NODE_STAT_STRUCT*>(req->ptr);*/
/*          argv[1] = BuildStatsObject(s);*/
        }
        break;

      case UV_FS_READLINK:
/*        argv[1] = String::New(static_cast<char*>(req->ptr));*/
        break;

      case UV_FS_READ:
        argc = 2;
        lua_pushlstring(L, ref->buf, req->result);
        lua_pushinteger(L, req->result);
        free(ref->buf);
        break;

      case UV_FS_READDIR:
        {
/*          char *namebuf = static_cast<char*>(req->ptr);*/
/*          int nnames = req->result;*/

/*          Local<Array> names = Array::New(nnames);*/

/*          for (int i = 0; i < nnames; i++) {*/
/*            Local<String> name = String::New(namebuf);*/
/*            names->Set(Integer::New(i), name);*/
/*#ifndef NDEBUG*/
/*            namebuf += strlen(namebuf);*/
/*            assert(*namebuf == '\0');*/
/*            namebuf += 1;*/
/*#else*/
/*            namebuf += strlen(namebuf) + 1;*/
/*#endif*/
/*          }*/

/*          argv[1] = names;*/
        }
        break;

      default:
        assert(0 && "Unhandled eio response");
    }

    if (lua_pcall(L, argc, 0, 0) != 0) {
      error(L, "error running function 'on_after_fs': %s", lua_tostring(L, -1));
    }


  }

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
    error(L, "fs_open: %s", uv_strerror(err));
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
    error(L, "fs_close: %s", uv_strerror(err));
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
    error(L, "fs_read: %s", uv_strerror(err));
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
    error(L, "fs_write: %s", uv_strerror(err));
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
    error(L, "fs_unlink: %s", uv_strerror(err));
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
    error(L, "fs_mkdir: %s", uv_strerror(err));
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
    error(L, "fs_rmdir: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_fs_stat(lua_State* L) {
  error(L, "TODO: Implement luv_fs_stat");
  return 0;
}

int luv_fs_fstat(lua_State* L) {
  error(L, "TODO: Implement luv_fs_fstat");
  return 0;
}

int luv_fs_rename(lua_State* L) {
  error(L, "TODO: Implement luv_fs_rename");
  return 0;
}

int luv_fs_fsync(lua_State* L) {
  error(L, "TODO: Implement luv_fs_fsync");
  return 0;
}

int luv_fs_fdatasync(lua_State* L) {
  error(L, "TODO: Implement luv_fs_fdatasync");
  return 0;
}

int luv_fs_ftruncate(lua_State* L) {
  error(L, "TODO: Implement luv_fs_ftruncate");
  return 0;
}

int luv_fs_sendfile(lua_State* L) {
  error(L, "TODO: Implement luv_fs_sendfile");
  return 0;
}

int luv_fs_chmod(lua_State* L) {
  error(L, "TODO: Implement luv_fs_chmod");
  return 0;
}

int luv_fs_utime(lua_State* L) {
  error(L, "TODO: Implement luv_fs_utime");
  return 0;
}

int luv_fs_futime(lua_State* L) {
  error(L, "TODO: Implement luv_fs_futime");
  return 0;
}

int luv_fs_lstat(lua_State* L) {
  error(L, "TODO: Implement luv_fs_lstat");
  return 0;
}

int luv_fs_link(lua_State* L) {
  error(L, "TODO: Implement luv_fs_link");
  return 0;
}

int luv_fs_symlink(lua_State* L) {
  error(L, "TODO: Implement luv_fs_symlink");
  return 0;
}

int luv_fs_readlink(lua_State* L) {
  error(L, "TODO: Implement luv_fs_readlink");
  return 0;
}

int luv_fs_fchmod(lua_State* L) {
  error(L, "TODO: Implement luv_fs_fchmod");
  return 0;
}

int luv_fs_chown(lua_State* L) {
  error(L, "TODO: Implement luv_fs_chown");
  return 0;
}

int luv_fs_fchown(lua_State* L) {
  error(L, "TODO: Implement luv_fs_fchown");
  return 0;
}

int luv_fs_event_init(lua_State* L) {
  error(L, "TODO: Implement luv_fs_event_init");
  return 0;
}


