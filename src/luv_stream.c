#include <stdlib.h>
#include <assert.h>

#include "luv_stream.h"

void luv_on_connection(uv_stream_t* handle, int status) {
  // load the lua state and the userdata
  luv_ref_t* ref = handle->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  lua_pushinteger(L, status);
  luv_emit_event(L, "connection", 1);
  lua_pop(L, 1); // remove the userdata
  assert(lua_gettop(L) == before);
}

void luv_on_read(uv_stream_t* handle, ssize_t nread, uv_buf_t buf) {

  // load the lua state and the userdata
  luv_ref_t* ref = handle->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  if (nread >= 0) {

    lua_pushlstring (L, buf.base, nread);
    lua_pushinteger (L, nread);
    luv_emit_event(L, "read", 2);

  } else {
    uv_err_t err = uv_last_error(uv_default_loop());
    if (err.code == UV_EOF) {
      luv_emit_event(L, "end", 0);
    } else {
      luaL_error(L, "read: %s", uv_strerror(err));
    }
  }
  lua_pop(L, 1); // Remove the userdata

  free(buf.base);
  assert(lua_gettop(L) == before);
}



void luv_after_shutdown(uv_shutdown_t* req, int status) {

  // load the lua state and the callback
  luv_shutdown_ref_t* ref = req->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  luaL_unref(L, LUA_REGISTRYINDEX, ref->r);

  lua_pushnumber(L, status);
  if (lua_pcall(L, 1, 0, 0) != 0) {
    luaL_error(L, "error running function 'on_shutdown': %s", lua_tostring(L, -1));
  }
  free(ref);// We're done with the ref object, free it
  assert(lua_gettop(L) == before);
}

void luv_after_write(uv_write_t* req, int status) {

  // load the lua state and the callback
  luv_write_ref_t* ref = req->data;
  lua_State *L = ref->L;
  int before = lua_gettop(L);
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  luaL_unref(L, LUA_REGISTRYINDEX, ref->r);
  lua_pushnumber(L, status);
  if (lua_pcall(L, 1, 0, 0) != 0) {
    luaL_error(L, "error running function 'on_write': %s", lua_tostring(L, -1));
  }
  free(ref);// We're done with the ref object, free it
  assert(lua_gettop(L) == before);

}

int luv_shutdown(lua_State* L) {
  int before = lua_gettop(L);
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  luaL_checktype(L, 2, LUA_TFUNCTION);
  luv_shutdown_ref_t* ref = (luv_shutdown_ref_t*)malloc(sizeof(luv_shutdown_ref_t));

  // Store a reference to the callback
  ref->L = L;
  lua_pushvalue(L, 2);
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  // Give the shutdown_req access to this
  ref->shutdown_req.data = ref;

  uv_shutdown(&ref->shutdown_req, handle, luv_after_shutdown);

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_listen (lua_State* L) {
  int before = lua_gettop(L);
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  luaL_checktype(L, 2, LUA_TFUNCTION);

  luv_register_event(L, 1, "connection", 2);

  if (uv_listen(handle, 128, luv_on_connection)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    luaL_error(L, "listen: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_accept (lua_State* L) {
  int before = lua_gettop(L);
  uv_stream_t* server = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  uv_stream_t* client = (uv_stream_t*)luv_checkudata(L, 2, "stream");
  if (uv_accept(server, client)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    luaL_error(L, "accept: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_read_start (lua_State* L) {
  int before = lua_gettop(L);
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  uv_read_start(handle, luv_on_alloc, luv_on_read);
  assert(lua_gettop(L) == before);
  return 0;
}

int luv_read_stop(lua_State* L) {
  int before = lua_gettop(L);
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  uv_read_stop(handle);
  assert(lua_gettop(L) == before);
  return 0;
}

int luv_write (lua_State* L) {
  int before = lua_gettop(L);
  uv_stream_t* handle = (uv_stream_t*)luv_checkudata(L, 1, "stream");
  size_t len;
  const char* chunk = luaL_checklstring(L, 2, &len);
  luaL_checktype(L, 3, LUA_TFUNCTION);

  luv_write_ref_t* ref = (luv_write_ref_t*)malloc(sizeof(luv_write_ref_t));

  // Store a reference to the callback
  ref->L = L;
  lua_pushvalue(L, 3);
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  // Give the write_req access to this
  ref->write_req.data = ref;

  // Store the chunk
  // TODO: this is probably unsafe, should investigate
  ref->refbuf.base = (char*)chunk;
  ref->refbuf.len = len;

  uv_write(&ref->write_req, handle, &ref->refbuf, 1, luv_after_write);
  assert(lua_gettop(L) == before);
  return 0;
}

