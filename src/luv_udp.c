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
#include "luv_udp.h"
#include "utils.h"

#define X(name, fn) \
  int luv_udp_##name(lua_State *L) { \
    uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp"); \
    int flag = luaL_checkint(L, 2); \
    int rc = fn(handle, flag); \
    if (rc) { \
      uv_err_t err = uv_last_error(luv_get_loop(L)); \
      return luaL_error(L, #name": %s", uv_strerror(err)); \
    } \
    return 0; \
  }

X(set_ttl, uv_udp_set_ttl);
X(set_broadcast, uv_udp_set_broadcast);
X(set_multicast_ttl, uv_udp_set_multicast_ttl);
X(set_multicast_loopback, uv_udp_set_multicast_loop);

#undef X

typedef struct {
  int ref;
} luv_udp_ref_t;

static void luv_on_udp_recv(uv_udp_t* handle,
                            ssize_t nread,
                            uv_buf_t buf,
                            struct sockaddr* addr,
                            unsigned flags) {
  int port = 0;
  char ip[INET6_ADDRSTRLEN];

  /* load the lua state and the userdata */
  lua_State *L = luv_handle_get_lua(handle->data);

  if (nread == 0) {
    free(buf.base);
    return;
  }

  if (nread < 0) {
    luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_recv", NULL);
    luv_emit_event(L, "error", 1);
    free(buf.base);
    return;
  }

  lua_pushlstring(L, buf.base, nread);
  lua_newtable(L);

  if (addr->sa_family == AF_INET) {
    uv_inet_ntop(AF_INET, &(((struct sockaddr_in*)addr)->sin_addr), ip, INET6_ADDRSTRLEN);
    port = ntohs(((struct sockaddr_in*)addr)->sin_port);
  } else if (addr->sa_family == AF_INET6){
    uv_inet_ntop(AF_INET6, &(((struct sockaddr_in6*)addr)->sin6_addr), ip, INET6_ADDRSTRLEN);
    port = ntohs(((struct sockaddr_in6*)addr)->sin6_port);
  }

  lua_pushstring(L, ip);
  lua_setfield(L, -2, "address");
  lua_pushnumber(L, port);
  lua_setfield(L, -2, "port");
  lua_pushboolean(L, flags == UV_UDP_PARTIAL);
  lua_setfield(L, -2, "partial");
  lua_pushnumber(L, nread);
  lua_setfield(L, -2, "size");
  luv_emit_event(L, "message", 2);

  free(buf.base);
  buf.base = NULL;
}

static void luv_on_udp_send(uv_udp_send_t* req, int status) {
  luv_udp_ref_t *ref;
  /* load the lua state and the userdata */
  lua_State *L = luv_handle_get_lua(req->handle->data);
  lua_pop(L, 1); /* We don't need the userdata */
  /* load the callback */
  ref =  req->data;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->ref);
  luaL_unref(L, LUA_REGISTRYINDEX, ref->ref);
  free(ref);

  if (lua_isfunction(L, -1)) {
    if (status != 0) {
      luv_push_async_error(L, uv_last_error(luv_get_loop(L)), "on_udp_send", NULL);
      luv_acall(L, 1, 0, "on_udp_send");
    } else {
      luv_acall(L, 0, 0, "on_udp_send");
    }
  } else {
    lua_pop(L, 1);
  }

  luv_handle_unref(L, req->handle->data);
  free(req);
}

int luv_new_udp (lua_State* L) {
  uv_udp_t* handle = luv_create_udp(L);
  /* uv_udp_init memset's the handle so we need to reset the data baton */
  void *data = handle->data;
  uv_udp_init(luv_get_loop(L), handle);
  handle->data = data;
  return 1;
}

static int luv__udp_bind(lua_State *L, int family) {
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  const char* host = luaL_checkstring(L, 2);
  int port = luaL_checkint(L, 3);
  int flags = 0;
  int rc = 0;

  switch (family) {
  case AF_INET:
    rc = uv_udp_bind(handle, uv_ip4_addr(host, port), flags);
    break;
  case AF_INET6:
    rc = uv_udp_bind6(handle, uv_ip6_addr(host, port), flags);
    break;
  default:
    assert(0 && "unexpected family type");
    abort();
  }

  if (rc) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "udp_bind: %s", uv_strerror(err));
  }

  return 0;
}

int luv_udp_bind(lua_State* L) {
  return luv__udp_bind(L, AF_INET);
}

int luv_udp_bind6(lua_State* L) {
  return luv__udp_bind(L, AF_INET6);
}

static const char *const luv_membership_options[] = {"join", "leave", NULL};

/*int uv_udp_set_membership(uv_udp_t* handle, const char* multicast_addr,*/
/*  const char* interface_addr, uv_membership membership);*/
int luv_udp_set_membership(lua_State* L) {
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  const char* multicast_addr = luaL_checkstring(L, 2);
  const char* interface_addr = luaL_checkstring(L, 3);
  int option = luaL_checkoption (L, 4, "membership", luv_membership_options);
  uv_membership membership = option ? UV_LEAVE_GROUP : UV_JOIN_GROUP;

  if (uv_udp_set_membership(handle, multicast_addr, interface_addr, membership)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "udp_set_membership: %s", uv_strerror(err));
  }

  return 0;
}

int luv_udp_getsockname(lua_State* L) {
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  int family;
  int port = 0;
  char ip[INET6_ADDRSTRLEN];

  struct sockaddr_storage address;
  int addrlen = sizeof(address);

  if (uv_udp_getsockname(handle, (struct sockaddr*)(&address), &addrlen)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "udp_getsockname: %s", uv_strerror(err));
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

  return 1;
}

static int luv_udp__send(lua_State* L, int family) {
  uv_buf_t buf;
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  size_t len;
  const char* chunk = luaL_checklstring(L, 2, &len);
  luv_udp_ref_t *ref;

  uv_udp_send_t* req = (uv_udp_send_t*)malloc(sizeof(uv_udp_send_t));
  int port = luaL_checkint(L, 3);
  const char* host = luaL_checkstring(L, 4);
  struct sockaddr_in dest;
  struct sockaddr_in6 dest6;
  int rc;

  /* Store a reference to the callback */
  lua_pushvalue(L, 5);
  ref = malloc(sizeof(*ref));
  ref->ref = luaL_ref(L, LUA_REGISTRYINDEX);
  req->data = ref;

  luv_handle_ref(L, handle->data, 1);

  /* Store the chunk
   * TODO: this is probably unsafe, should investigate
   */
  buf = uv_buf_init((char*)chunk, len);

  switch(family) {
  case AF_INET:
    dest = uv_ip4_addr(host, port);
    rc = uv_udp_send(req, handle, &buf, 1, dest, luv_on_udp_send);
    break;
  case AF_INET6:
    dest6 = uv_ip6_addr(host, port);
    rc = uv_udp_send6(req, handle, &buf, 1, dest6, luv_on_udp_send);
    break;
  default:
    assert(0 && "unexpected family type");
    abort();
  }

  if (rc) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "udp_send: %s", uv_strerror(err));
  }

  return 0;
}

int luv_udp_send(lua_State* L) {
  return luv_udp__send(L, AF_INET);
}

int luv_udp_send6(lua_State* L) {
  return luv_udp__send(L, AF_INET6);
}

int luv_udp_recv_start(lua_State* L) {
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  int rc = uv_udp_recv_start(handle, luv_on_alloc, luv_on_udp_recv);
  if (rc && uv_last_error(luv_get_loop(L)).code != UV_EALREADY) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "udp_recv_start: %s", uv_strerror(err));
  }
  luv_handle_ref(L, handle->data, 1);
  return 0;
}

int luv_udp_recv_stop(lua_State* L) {
  uv_udp_t* handle = (uv_udp_t*)luv_checkudata(L, 1, "udp");
  if (uv_udp_recv_stop(handle)) {
    uv_err_t err = uv_last_error(luv_get_loop(L));
    return luaL_error(L, "udp_recv_stop: %s", uv_strerror(err));
  }
  luv_handle_unref(L, handle->data);
  return 0;
}

