#include "luv.h"
#include "uv.h"
#include <stdlib.h>

static int luv_run (lua_State* L) {
  uv_run(uv_default_loop());
  return 0;
}

static int luv_new_tcp (lua_State* L) {

  uv_tcp_t* handle = (uv_tcp_t*)lua_newuserdata(L, sizeof(uv_tcp_t));

  // Store a reference to the userdata in the handle
  luv_ref* ref = (luv_ref*)malloc(sizeof(luv_ref));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  uv_tcp_init(uv_default_loop(), handle);

  // Set instance methods
  luaL_getmetatable(L, "luv_tcp");
  lua_setmetatable(L, -2);
  
  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // return the userdata
  return 1;
}

static int luv_tcp_init (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  uv_tcp_init(uv_default_loop(), handle);
  return 0;
}

static int luv_tcp_bind (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);

  struct sockaddr_in address = uv_ip4_addr(host, port);
  int r = uv_tcp_bind(handle, address);

  // return r
  lua_pushnumber(L, r);
  return 1;
}

void luv_on_connection(uv_stream_t* handle, int status) {
  // load the lua state and the userdata
  luv_ref* ref = handle->data;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  // Load the connection callback
  lua_getfenv(L, -1);
  lua_getfield(L, -1, "connection");
  lua_remove(L, -2);
  
  if (lua_isfunction (L, -1) == 0) {
    printf("missing: on_connection\n");
  } else {
    lua_pushinteger(L, status);
    if (lua_pcall(L, 1, 1, 0) != 0) {
      error(L, "error running function 'on_connection': %s", lua_tostring(L, -1));
    }
  }
  
  // Clean up the callback
  lua_pop(L, 1);
}

static int luv_tcp_on (lua_State* L) {
  luaL_checkudata(L, 1, "luv_tcp");
  const char* name = luaL_checkstring(L, 2);
  luaL_checktype(L, 3, LUA_TFUNCTION);

  // Store the callback in the environment as "on_connection"
  lua_getfenv(L, 1);
  lua_pushvalue(L, 3); // put callback on stack
  lua_setfield(L, -2, name);
  lua_pop(L, 1); // put env away
  
  return 0;
  
}


static int luv_tcp_listen (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  int r = uv_listen((uv_stream_t*)handle, 128, luv_on_connection);
  lua_pushinteger(L, r);
  return 1;
}

static int luv_tcp_accept (lua_State* L) {
  uv_tcp_t* server = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  uv_tcp_t* client = (uv_tcp_t*)luaL_checkudata(L, 2, "luv_tcp");
  int r = uv_accept((uv_stream_t*)server, (uv_stream_t*)client);
  lua_pushinteger(L, r);
  return 1;
}

uv_buf_t luv_on_alloc(uv_handle_t* handle, size_t suggested_size) {
  uv_buf_t buf;
  buf.base = malloc(suggested_size);
  buf.len = suggested_size;
  return buf;
}

void luv_on_close(uv_handle_t* handle) {

  // load the lua state and the userdata
  luv_ref* ref = handle->data;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  lua_getfenv(L, -1);
  lua_getfield(L, -1, "close");
  lua_remove(L, -2);

  if (lua_isfunction (L, -1) == 0) {
    printf("missing: on_close\n");
  } else {
    if (lua_pcall(L, 0, 1, 0) != 0) {
      error(L, "error running function 'on_close': %s", lua_tostring(L, -1));
    }
  }
}


void luv_on_read(uv_stream_t* handle, ssize_t nread, uv_buf_t buf) {

  // load the lua state and the userdata
  luv_ref* ref = handle->data;
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);

  if (nread >= 0) {

    // Load the read callback
    lua_getfenv(L, -1);
    lua_getfield(L, -1, "read");
    lua_remove(L, -2);
    
    if (lua_isfunction (L, -1) == 0) {
      printf("missing: on_read\n");
    } else {
      lua_pushlstring (L, buf.base, nread);
      if (lua_pcall(L, 1, 1, 0) != 0) {
        error(L, "error running function 'on_read': %s", lua_tostring(L, -1));
      }
    }
    
    // clean up the callback
    lua_pop(L, 1);

  } else {
    uv_err_t err = uv_last_error(uv_default_loop());
    if (err.code == UV_EOF) {
      uv_close((uv_handle_t*)handle, luv_on_close);
    } else {
      error(L, "read: %s", uv_strerror(err));
    }
  }

  free(buf.base);

}

static int luv_tcp_read_start (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luaL_checkudata(L, 1, "luv_tcp");
  uv_read_start((uv_stream_t*)handle, luv_on_alloc, luv_on_read);
  return 0;
}

static const luaL_reg luv_tcp_m[] = {
  {"init", luv_tcp_init},
  {"bind", luv_tcp_bind},
  {"listen", luv_tcp_listen},
  {"accept", luv_tcp_accept},
  {"on", luv_tcp_on},
  {"read_start", luv_tcp_read_start},
  {NULL, NULL}
};

static const luaL_reg luv_f[] = {
  {"new_tcp", luv_new_tcp},
  {"run", luv_run},
  {NULL, NULL}
};


LUALIB_API int luaopen_uv (lua_State* L) {

  // Define the luv_tcp userdata's methods
  luaL_newmetatable(L, "luv_tcp");
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  luaL_register(L, NULL, luv_tcp_m);
  lua_pop(L, 1);

  // Create a new exports table with functions and constants
  lua_newtable (L);
  luaL_register(L, NULL, luv_f);
  lua_pushnumber(L, UV_VERSION_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, UV_VERSION_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");

  return 1;
}

