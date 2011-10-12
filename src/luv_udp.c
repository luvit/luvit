#include <stdlib.h>
#include <assert.h>

#include "luv_udp.h"

void luv_on_udp_recv(uv_udp_t* handle, ssize_t nread, uv_buf_t buf, struct sockaddr* addr, unsigned flags) {
  printf("TODO: implement luv_on_udp_recv\n");
}

int luv_new_udp (lua_State* L) {
  int before = lua_gettop(L);
  uv_udp_t* handle = (uv_udp_t*)lua_newuserdata(L, sizeof(uv_udp_t));
  uv_udp_init(uv_default_loop(), handle);

  // Set metatable for type
  luaL_getmetatable(L, "luv_udp");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // Store a reference to the userdata in the handle
  luv_ref_t* ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  assert(lua_gettop(L) == before + 1);
  // return the userdata
  return 1;
}

int luv_udp_bind(lua_State* L) {
  int before = lua_gettop(L);
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);
  int flags = 0;

  struct sockaddr_in address = uv_ip4_addr(host, port);

  if (uv_udp_bind(handle, address, flags)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "udp_bind: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_udp_bind6(lua_State* L) {
  int before = lua_gettop(L);
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);
  int flags = 0;

  struct sockaddr_in6 address = uv_ip6_addr(host, port);

  if (uv_udp_bind6(handle, address, flags)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "udp_bind: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_udp_set_membership(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_udp_set_membership");
}

int luv_udp_getsockname(lua_State* L) {
  int before = lua_gettop(L);
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");

  struct sockaddr_storage address;
  int addrlen = sizeof(address);

  if (uv_udp_getsockname(handle, (struct sockaddr*)(&address), &addrlen)) {
    uv_err_t err = uv_last_error(uv_default_loop());
    return luaL_error(L, "udp_getsockname: %s", uv_strerror(err));
  }

  int family = address.ss_family;
  int port;
  char ip[INET6_ADDRSTRLEN];
  if (family == AF_INET) {
    struct sockaddr_in* addrin = (struct sockaddr_in*)&address;
    uv_inet_ntop(AF_INET, &(addrin->sin_addr), ip, INET6_ADDRSTRLEN);
    port = ntohs(addrin->sin_port);
  } else if (family == AF_INET6) {
    struct sockaddr_in6* addrin6 = (struct sockaddr_in6*)&address;
    uv_inet_ntop(AF_INET6, &(addrin6->sin6_addr), ip, INET6_ADDRSTRLEN);
    port = ntohs(addrin6->sin6_port);
  }

  lua_newtable(L);
  lua_pushnumber(L, port);
  lua_setfield(L, -2, "port");
  lua_pushnumber(L, family);
  lua_setfield(L, -2, "family");
  lua_pushstring(L, ip);
  lua_setfield(L, -2, "address");

  assert(lua_gettop(L) == before + 1);
  return 1;
}

int luv_udp_send(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_udp_send");
}

int luv_udp_send6(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_udp_send6");
}

int luv_udp_recv_start(lua_State* L) {
  int before = lua_gettop(L);
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  uv_udp_recv_start(handle, luv_on_alloc, luv_on_udp_recv);
  assert(lua_gettop(L) == before);
  return 0;
}

int luv_udp_recv_stop(lua_State* L) {
  int before = lua_gettop(L);
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  uv_udp_recv_stop(handle);
  assert(lua_gettop(L) == before);
  return 0;
}

