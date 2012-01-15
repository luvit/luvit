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

#include <stdlib.h>
#include <assert.h>

#include "luv_portability.h"
#include "luv_tcp.h"
#include "utils.h"

int luv_new_tcp (lua_State* L) {
  int before = lua_gettop(L);
  luv_ref_t* ref;

  uv_tcp_t* handle = (uv_tcp_t*)lua_newuserdata(L, sizeof(uv_tcp_t));
  uv_tcp_init(luv_get_loop(L), handle);

  // Set metatable for type
  luaL_getmetatable(L, "luv_tcp");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  // Store a reference to the userdata in the handle
  ref = (luv_ref_t*)malloc(sizeof(luv_ref_t));
  ref->L = L;
  lua_pushvalue(L, -1); // duplicate so we can _ref it
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  handle->data = ref;

  assert(lua_gettop(L) == before + 1);
  // return the userdata
  return 1;
}

int luv_tcp_nodelay (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");
  int enable = lua_toboolean(L, 2);

  if (uv_tcp_nodelay(handle, enable)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_nodelay: %s", uv_strerror(err));
  }
  return 0;
}

int luv_tcp_keepalive (lua_State* L) {
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");
  int enable = lua_toboolean(L, 2);
  int delay = lua_tointeger(L, 3);

  if (uv_tcp_keepalive(handle, enable, delay)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_keepalive: %s", uv_strerror(err));
  }
  return 0;

}


int luv_tcp_bind (lua_State* L) {
  int before = lua_gettop(L);
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);

  struct sockaddr_in address = uv_ip4_addr(host, port);

  if (uv_tcp_bind(handle, address)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_bind: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_tcp_bind6(lua_State* L) {
  int before = lua_gettop(L);
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);

  struct sockaddr_in6 address = uv_ip6_addr(host, port);

  if (uv_tcp_bind6(handle, address)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_bind6: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_tcp_getsockname(lua_State* L) {
  int before = lua_gettop(L);
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");
  int port;
  char ip[INET6_ADDRSTRLEN];
  int family;

  struct sockaddr_storage address;
  int addrlen = sizeof(address);

  if (uv_tcp_getsockname(handle, (struct sockaddr*)(&address), &addrlen)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_getsockname: %s", uv_strerror(err));
  }

  family = address.ss_family;
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

int luv_tcp_getpeername(lua_State* L) {
  int before = lua_gettop(L);
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");
  int port;
  char ip[INET6_ADDRSTRLEN];
  int family;

  struct sockaddr_storage address;
  int addrlen = sizeof(address);

  if (uv_tcp_getpeername(handle, (struct sockaddr*)(&address), &addrlen)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_getpeername: %s", uv_strerror(err));
  }

  family = address.ss_family;
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

int luv_tcp_connect(lua_State* L) {
  int before = lua_gettop(L);
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");

  const char* ip_address = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);

  struct sockaddr_in address = uv_ip4_addr(ip_address, port);

  luv_connect_ref_t* ref = (luv_connect_ref_t*)malloc(sizeof(luv_connect_ref_t));

  // Store a reference to the userdata
  ref->L = L;
  lua_pushvalue(L, 1);
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  // Give the connect_req access to this
  ref->connect_req.data = ref;

  if (uv_tcp_connect(&ref->connect_req, handle, address, luv_after_connect)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_connect: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

int luv_tcp_connect6(lua_State* L) {
  int before = lua_gettop(L);
  uv_tcp_t* handle = (uv_tcp_t*)luv_checkudata(L, 1, "tcp");

  const char* ip_address = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);

  struct sockaddr_in6 address = uv_ip6_addr(ip_address, port);

  luv_connect_ref_t* ref = (luv_connect_ref_t*)malloc(sizeof(luv_connect_ref_t));

  // Store a reference to the userdata
  ref->L = L;
  lua_pushvalue(L, 1);
  ref->r = luaL_ref(L, LUA_REGISTRYINDEX);

  // Give the connect_req access to this
  ref->connect_req.data = ref;

  if (uv_tcp_connect6(&ref->connect_req, handle, address, luv_after_connect)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "tcp_connect6: %s", uv_strerror(err));
  }

  assert(lua_gettop(L) == before);
  return 0;
}

