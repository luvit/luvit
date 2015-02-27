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

#include <sys/types.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "luv_portability.h"
#include "luv_dns.h"
#include "ares.h"
#include "tree.h"
#include "utils.h"

static ares_channel luv_ares_channel;
static uv_timer_t ares_timer;

typedef struct {
  lua_State* L;
  int r;
  uv_getaddrinfo_t handle;
} luv_dns_ref_t;

typedef struct ares_task_t {
  UV_HANDLE_FIELDS
  ares_socket_t sock;
  uv_poll_t poll_watcher;
  RB_ENTRY(ares_task_t) node;
} ares_task_t;

#ifndef offset_of
# define offset_of(type, member) \
  ((intptr_t)( \
      (char*)(&(((type*)(0))->member))))
#endif

#ifndef container_of
# define container_of(ptr, type, member) \
  ((type*)((char*)(ptr) - \
                           offset_of(type, member)))
#endif

/* ares tree task list */
static RB_HEAD(ares_task_list, ares_task_t) ares_tasks;

/* ares_tasks tree sort */
static int cmp_ares_tasks(const ares_task_t* a, const ares_task_t* b) {
  if (a->sock < b->sock) return -1;
  if (a->sock > b->sock) return 1;
  return 0;
}

/* generate functions for the ares_tasks tree */
RB_GENERATE_STATIC(ares_task_list, ares_task_t, node, cmp_ares_tasks);


/* This is called once per second by loop->timer. It is used to constantly */
/* call back into c-ares for possibly processing timeouts. */
static void luv_ares_timeout(uv_timer_t* handle, int status) {
  assert(!RB_EMPTY(&ares_tasks));
  ares_process_fd(luv_ares_channel, ARES_SOCKET_BAD, ARES_SOCKET_BAD);
}


static void luv_ares_poll_cb(uv_poll_t* watcher, int status, int events) {
  ares_task_t* task = container_of(watcher, ares_task_t, poll_watcher);

  /* Reset the idle timer */
  uv_timer_again(&ares_timer);

  if (status < 0) {
    /* An error happened. Just pretend that the socket is both readable and */
    /* writable. */
    ares_process_fd(luv_ares_channel, task->sock, task->sock);
    return;
  }

  /* Process DNS responses */
  ares_process_fd(luv_ares_channel,
                  events & UV_READABLE ? task->sock : ARES_SOCKET_BAD,
                  events & UV_WRITABLE ? task->sock : ARES_SOCKET_BAD);
}


static void ares_poll_close_cb(uv_handle_t* watcher) {
  ares_task_t* task = container_of(watcher, ares_task_t, poll_watcher);
  free(task);
}


/* Allocates and returns a new ares_task_t */
static ares_task_t* ares_task_create(uv_loop_t* loop, ares_socket_t sock) {
  ares_task_t* task = (ares_task_t*)(malloc(sizeof(*task)));

  if (task == NULL) {
    /* Out of memory. */
    return NULL;
  }

  task->loop = loop;
  task->sock = sock;

  if (uv_poll_init_socket(loop, &task->poll_watcher, sock) < 0) {
    /* This should never happen. */
    free(task);
    return NULL;
  }

  return task;
}


/* Callback from ares when socket operation is started */
static void ares_sockstate_cb(void* data,
                              ares_socket_t sock,
                              int read,
                              int write) {
  uv_loop_t* loop = (uv_loop_t*)(data);
  ares_task_t* task;

  ares_task_t lookup_task;
  lookup_task.sock = sock;
  task = RB_FIND(ares_task_list, &ares_tasks, &lookup_task);

  if (read || write) {
    if (!task) {
      /* New socket */

      /* If this is the first socket then start the timer. */
      if (!uv_is_active((uv_handle_t*)(&ares_timer))) {
        assert(RB_EMPTY(&ares_tasks));
        uv_timer_start(&ares_timer, luv_ares_timeout, 1000, 1000);
      }

      task = ares_task_create(loop, sock);
      if (task == NULL) {
        /* This should never happen unless we're out of memory or something */
        /* is seriously wrong. The socket won't be polled, but the the query */
        /* will eventually time out. */
        return;
      }

      RB_INSERT(ares_task_list, &ares_tasks, task);
    }

    /* This should never fail. If it fails anyway, the query will eventually */
    /* time out. */
    uv_poll_start(&task->poll_watcher,
                  (read ? UV_READABLE : 0) | (write ? UV_WRITABLE : 0),
                  luv_ares_poll_cb);

  } else {
    /* read == 0 and write == 0 this is c-ares's way of notifying us that */
    /* the socket is now closed. We must free the data associated with */
    /* socket. */
    assert(task &&
           "When an ares socket is closed we should have a handle for it");

    RB_REMOVE(ares_task_list, &ares_tasks, task);
    uv_close((uv_handle_t*)(&task->poll_watcher),
             ares_poll_close_cb);

    if (RB_EMPTY(&ares_tasks)) {
      uv_timer_stop(&ares_timer);
    }
  }
}


/* Set up ares and corresponding timers */
void luv_dns_initialize(lua_State *L) {
  int r;
  struct ares_options options;
  uv_loop_t* loop = luv_get_loop(L);

  r = ares_library_init(ARES_LIB_INIT_ALL);
  assert(r == ARES_SUCCESS);

  memset(&options, 0, sizeof(options));
  options.flags = ARES_FLAG_NOCHECKRESP;
  options.sock_state_cb = ares_sockstate_cb;
  options.sock_state_cb_data = loop;

  /* We do the call to ares_init_option for caller. */
  r = ares_init_options(&luv_ares_channel,
                        &options,
                        ARES_OPT_FLAGS | ARES_OPT_SOCK_STATE_CB);
  assert(r == ARES_SUCCESS);

  /* store channel */
  luv_set_ares_channel(L, luv_ares_channel);

  /* Initialize the timeout timer. The timer won't be started until the */
  /* first socket is opened. */
  uv_timer_init(loop, &ares_timer);
}


/* Utility for storing the callback in the dns_req token */
static luv_dns_ref_t* luv_dns_store_callback(lua_State* L, int index) {
  luv_dns_ref_t* ref;

  ref = calloc(1, sizeof(luv_dns_ref_t));
  ref->L = L;
  if (lua_isfunction(L, index)) {
    lua_pushvalue(L, index); /* Store the callback */
    ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  }
  return ref;
}

static void luv_dns_ref_cleanup(luv_dns_ref_t *ref)
{
  assert(ref != NULL);
  free(ref);
}

static void luv_dns_get_callback(luv_dns_ref_t *ref)
{
  lua_State *L = ref->L;
  lua_rawgeti(L, LUA_REGISTRYINDEX, ref->r);
  luaL_unref(L, LUA_REGISTRYINDEX, ref->r);
}

static void luv_addresses_to_array(lua_State *L, struct hostent *host)
{
  char ip[INET6_ADDRSTRLEN];
  int i;

  lua_newtable(L);
  for (i=0; host->h_addr_list[i]; ++i) {
    uv_inet_ntop(host->h_addrtype, host->h_addr_list[i], ip, sizeof(ip));
    lua_pushstring(L, ip);
    lua_rawseti(L, -2, i+1);
  }
}

static void luv_aliases_to_array(lua_State *L, struct hostent *host)
{
  int i;
  lua_newtable(L);
  for (i=0; host->h_aliases[i]; ++i) {
    lua_pushstring(L, host->h_aliases[i]);
    lua_rawseti(L, -2, i+1);
  }
}

/* From NodeJS */
static const char* ares_errno_string(int errorno)
{
  switch (errorno) {
    #define ERRNO_CASE(e) case ARES_##e: return #e;
    ERRNO_CASE(SUCCESS)
    ERRNO_CASE(ENODATA)
    ERRNO_CASE(EFORMERR)
    ERRNO_CASE(ESERVFAIL)
    ERRNO_CASE(ENOTFOUND)
    ERRNO_CASE(ENOTIMP)
    ERRNO_CASE(EREFUSED)
    ERRNO_CASE(EBADQUERY)
    ERRNO_CASE(EBADNAME)
    ERRNO_CASE(EBADFAMILY)
    ERRNO_CASE(EBADRESP)
    ERRNO_CASE(ECONNREFUSED)
    ERRNO_CASE(ETIMEOUT)
    ERRNO_CASE(EOF)
    ERRNO_CASE(EFILE)
    ERRNO_CASE(ENOMEM)
    ERRNO_CASE(EDESTRUCTION)
    ERRNO_CASE(EBADSTR)
    ERRNO_CASE(EBADFLAGS)
    ERRNO_CASE(ENONAME)
    ERRNO_CASE(EBADHINTS)
    ERRNO_CASE(ENOTINITIALIZED)
    ERRNO_CASE(ELOADIPHLPAPI)
    ERRNO_CASE(EADDRGETNETWORKPARAMS)
    ERRNO_CASE(ECANCELLED)
    #undef ERRNO_CASE
  default:
    assert(0 && "Unhandled c-ares error");
    return "(UNKNOWN)";
  }
}

static void luv_push_gai_async_error(lua_State *L, int status, const char* source)
{
  char code_str[32];
  snprintf(code_str, sizeof(code_str), "%i", status);
  /* NOTE: gai_strerror() is _not_ threadsafe on Windows */
  luv_push_async_error_raw(L, code_str, gai_strerror(status), source, NULL);
  if (lua_isfunction(L, 3) == 1) {
    luv_acall(L, 1, 0, "dns_after");
  }
}

/* Pushes an error object onto the stack */
static void luv_push_ares_async_error(lua_State* L, int rc, const char* source)
{
  char code_str[32];
  snprintf(code_str, sizeof(code_str), "%i", rc);
  luv_push_async_error_raw(L, code_str, ares_errno_string(rc), source, NULL);
  luv_acall(L, 1, 0, "dns_after");
}

static void queryA_callback(void *arg, int status, int timeouts,
                            unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct hostent* host;
  int rc;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "queryA");
    goto cleanup;
  }

  rc = ares_parse_a_reply(buf, len, &host, NULL, NULL);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryA");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  luv_addresses_to_array(ref->L, host);
  luv_acall(ref->L, 2, 0, "dns_after");
  ares_free_hostent(host);

cleanup:
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryA(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_a, queryA_callback, ref);
  return 0;
}

static void queryAaaa_callback(void *arg, int status, int timeouts,
                               unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct hostent* host;
  int rc;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "queryAaaa");
    goto cleanup;
  }

  rc = ares_parse_aaaa_reply(buf, len, &host, NULL, NULL);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryAaaa");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  luv_addresses_to_array(ref->L, host);
  luv_acall(ref->L, 2, 0, "dns_after");
  ares_free_hostent(host);

cleanup:
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryAaaa(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_aaaa, queryAaaa_callback, ref);
  return 0;
}

static void queryCname_callback(void *arg, int status, int timeouts,
                                unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct hostent* host;
  int rc;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "queryCname");
    goto cleanup;
  }

  rc = ares_parse_a_reply(buf, len, &host, NULL, NULL);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryCname");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  lua_newtable(ref->L); /* result table */
  lua_pushstring(ref->L, host->h_name);
  lua_rawseti(ref->L, -2, 1);
  luv_acall(ref->L, 2, 0, "dns_after");

  ares_free_hostent(host);

cleanup:
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryCname(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_cname, queryCname_callback, ref);
  return 0;
}

static void queryMx_callback(void *arg, int status, int timeouts,
                             unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct ares_mx_reply *start;
  struct ares_mx_reply *curr;
  int rc, i;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "queryMx");
    goto cleanup;
  }

  rc = ares_parse_mx_reply(buf, len, &start);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryMx");
    goto cleanup;
  }

  lua_pushnil(ref->L); /* err */
  lua_newtable(ref->L); /* result table */

  for (curr=start, i=1; curr; curr=curr->next, i++) {
    lua_newtable(ref->L);

    lua_pushstring(ref->L, curr->host);
    lua_setfield(ref->L, -2, "exchange");

    lua_pushnumber(ref->L, curr->priority);
    lua_setfield(ref->L, -2, "priority");

    lua_rawseti(ref->L, -2, i);
  }

  luv_acall(ref->L, 2, 0, "dns_after");

  ares_free_data(start);
cleanup:
  luv_dns_ref_cleanup(ref);
}


int luv_dns_queryMx(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_mx, queryMx_callback, ref);
  return 0;
}

static void queryNs_callback(void *arg, int status, int timeouts,
                             unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct hostent* host;
  int rc;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "queryNs");
    goto cleanup;
  }

  rc = ares_parse_ns_reply(buf, len, &host);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryNs");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  luv_aliases_to_array(ref->L, host);
  luv_acall(ref->L, 2, 0, "dns_after");
  ares_free_hostent(host);

cleanup:
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryNs(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_ns, queryNs_callback, ref);
  return 0;
}

static void queryTxt_callback(void *arg, int status, int timeouts,
                              unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct ares_txt_reply *start, *curr;
  int rc, i;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "queryTxt");
    goto cleanup;
  }

  rc = ares_parse_txt_reply(buf, len, &start);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryTxt");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  lua_newtable(ref->L);
  for (i=0, curr=start; curr; ++i, curr=curr->next) {
    lua_pushstring(ref->L, (const char*)curr->txt);
    lua_rawseti(ref->L, -2, i+1);
  }

  luv_acall(ref->L, 2, 0, "dns_after");
  ares_free_data(start);

cleanup:
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryTxt(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_txt, queryTxt_callback, ref);
  return 0;
}

static void querySrv_callback(void *arg, int status, int timeouts,
                              unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct ares_srv_reply *start, *curr;
  int rc, i;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "querySrv");
    goto cleanup;
  }

  rc = ares_parse_srv_reply(buf, len, &start);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "querySrv");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  lua_newtable(ref->L);

  for (curr=start, i=1; curr; curr=curr->next, i++) {
    lua_newtable(ref->L);

    lua_pushstring(ref->L, curr->host);
    lua_setfield(ref->L, -2, "name");

    lua_pushnumber(ref->L, curr->port);
    lua_setfield(ref->L, -2, "port");

    lua_pushnumber(ref->L, curr->priority);
    lua_setfield(ref->L, -2, "priority");

    lua_pushnumber(ref->L, curr->weight);
    lua_setfield(ref->L, -2, "weight");

    lua_rawseti(ref->L, -2, i);
  }

  luv_acall(ref->L, 2, 0, "dns_after");
  ares_free_data(start);

cleanup:
  luv_dns_ref_cleanup(ref);
}

int luv_dns_querySrv(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_srv, querySrv_callback, ref);
  return 0;
}

static void getHostByAddr_callback(void *arg, int status,int timeouts,
                                   struct hostent *host)
{
  luv_dns_ref_t *ref = arg;

  luv_dns_get_callback(ref);

  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, status, "gethostbyaddr");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  luv_aliases_to_array(ref->L, host);
  luv_acall(ref->L, 2, 0, "dns_after");

cleanup:
  luv_dns_ref_cleanup(ref);
}

int luv_dns_getHostByAddr(lua_State* L)
{
  ares_channel channel = luv_get_ares_channel(L);
  char address_buffer[sizeof(struct in6_addr)];
  int length, family;
  const char* ip = luaL_checkstring(L, 1);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 2);

  if (ares_inet_pton(AF_INET, ip, &address_buffer) == 1) {
    length = sizeof(struct in_addr);
    family = AF_INET;
  } else if (ares_inet_pton(AF_INET6, ip, &address_buffer) == 1) {
    length = sizeof(struct in6_addr);
    family = AF_INET6;
  } else {
    luv_dns_get_callback(ref);
    if (lua_isfunction(ref->L, -1) == 1) {
      luv_push_ares_async_error(ref->L, ARES_EBADSTR, "getHostByAddr");
      luv_dns_ref_cleanup(ref);
    }
    return 0;
  }

  ares_gethostbyaddr(channel, address_buffer, length, family,
                     getHostByAddr_callback, ref);
  return 0;
}

static void luv_dns_getaddrinfo_callback(uv_getaddrinfo_t* res, int status,
                                         struct addrinfo* start)
{
  luv_dns_ref_t* ref = res->data;
  struct addrinfo *curr;
  char ip[INET6_ADDRSTRLEN];
  const char *addr;
  int n = 1;

  luv_dns_get_callback(ref);
  if (lua_isfunction(ref->L, -1) == 0) {
    goto cleanup;
  }

  if (status) {
    luv_push_gai_async_error(ref->L, status, "getaddrinfo");
    goto cleanup;
  }

  lua_pushnil(ref->L);
  lua_newtable(ref->L);

  for (curr=start; curr; curr=curr->ai_next) {
    if (curr->ai_family == AF_INET || curr->ai_family == AF_INET6) {
      if (curr->ai_family == AF_INET) {
        addr = (char*) &((struct sockaddr_in*) curr->ai_addr)->sin_addr;
      } else {
        addr = (char*) &((struct sockaddr_in6*) curr->ai_addr)->sin6_addr;
      }
      uv_inet_ntop(curr->ai_family, addr, ip, INET6_ADDRSTRLEN);
      lua_pushstring(ref->L, ip);
      lua_rawseti(ref->L, -2, n++);
    }
  }
  luv_acall(ref->L, 2, 0, "dns_after");

cleanup:
  uv_freeaddrinfo(start);
  luv_dns_ref_cleanup(ref);
}

int luv_dns_getAddrInfo(lua_State* L)
{
  struct addrinfo hints;
  const char *hostname = luaL_checkstring(L, 1);
  int family = luaL_checknumber(L, 2);
  luv_dns_ref_t* ref = luv_dns_store_callback(L, 3);

  memset(&hints, 0, sizeof(hints));
  hints.ai_family = family;
  hints.ai_socktype = SOCK_STREAM;

  ref->handle.data = ref;
  uv_getaddrinfo(luv_get_loop(L), &ref->handle, luv_dns_getaddrinfo_callback,
                 hostname, NULL, &hints);
  return 0;
}

static int luv_dns__isIp(lua_State *L, const char *ip, int v4v6) {
  int family;
  char address_buffer[sizeof(struct in6_addr)];

  if (ares_inet_pton(AF_INET, ip, &address_buffer) == 1) {
    family = AF_INET;
  } else if (ares_inet_pton(AF_INET6, ip, &address_buffer) == 1) {
    family = AF_INET6;
  } else {
    /* failure */
    lua_pushnumber(L, 0);
    return 1;
  }

  if (v4v6 == 0) {
    lua_pushnumber(L, (family == AF_INET) ? 4 : 6);
  }
  else if (v4v6 == 4) {
    lua_pushnumber(L, (family == AF_INET) ? 4 : 0);
  }
  else {
    lua_pushnumber(L, (family == AF_INET6) ? 6 : 0);
  }
  return 1;
}

int luv_dns_isIp(lua_State* L)
{
  const char *ip = luaL_checkstring(L, 1);
  return luv_dns__isIp(L, ip, 0);
}

int luv_dns_isIpV4(lua_State* L)
{
  const char *ip = luaL_checkstring(L, 1);
  return luv_dns__isIp(L, ip, 4);
}

int luv_dns_isIpV6(lua_State* L) {
  const char *ip = luaL_checkstring(L, 1);
  return luv_dns__isIp(L, ip, 6);
}
