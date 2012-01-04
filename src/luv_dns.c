#include <sys/types.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "luv_dns.h"

#if defined(__OpenBSD__) || defined(__MINGW32__) || defined(_MSC_VER)
# include <nameser.h>
#else
# include <arpa/nameser.h>
#endif

// Temporary hack: libuv should provide uv_inet_pton and uv_inet_ntop.
#if defined(__MINGW32__) || defined(_MSC_VER)
  extern "C" {
#   include <inet_net_pton.h>
#   include <inet_ntop.h>
  }
# define uv_inet_pton ares_inet_pton
# define uv_inet_ntop ares_inet_ntop

#else // __POSIX__
# include <arpa/inet.h>
# define uv_inet_pton inet_pton
# define uv_inet_ntop inet_ntop
#endif

static ares_channel channel;
static struct ares_options options;

// Utility for storing the callback in the dns_req token
luv_dns_ref_t* luv_dns_store_callback(lua_State* L, int index) {
  int before = lua_gettop(L);
  luv_dns_ref_t* ref;

  ref = calloc(1, sizeof(luv_dns_ref_t));
  ref->L = L;
  if (lua_isfunction(L, index)) {
    lua_pushvalue(L, index); // Store the callback
    ref->r = luaL_ref(L, LUA_REGISTRYINDEX);
  }
  assert(lua_gettop(L) == before);
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

/** From NodeJS */
static const char* ares_errno_string(int errorno) {
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

// Pushes an error object onto the stack
static void luv_push_ares_async_error(lua_State* L, int rc, const char* source)
{
  char code_str[32];
  snprintf(code_str, sizeof(code_str), "%i", rc);
  luv_push_async_error_raw(L, code_str, ares_errno_string(rc), "queryA", NULL);
}

static void queryA_callback(void *arg, int status, int timeouts,
                            unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct hostent* host;
  char ip[INET6_ADDRSTRLEN];
  int rc, i;

  luv_dns_get_callback(ref);

  rc = ares_parse_a_reply(buf, len, &host, NULL, NULL);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryA");
    luv_acall(ref->L, 1, 0, "dns_after");
    return;
  }

  lua_pushnil(ref->L);
  lua_newtable(ref->L);
  for (i = 0; host->h_addr_list[i]; ++i) {
    uv_inet_ntop(host->h_addrtype, host->h_addr_list[i], ip, sizeof(ip));
    lua_pushstring(ref->L, ip);
    lua_rawseti(ref->L, -2, i+1);
  }

  luv_acall(ref->L, 2, 0, "dns_after");
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryA(lua_State* L)
{
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* req = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_a, queryA_callback, req);
  return 0;
}

static void queryAAAA_callback(void *arg, int status, int timeouts,
                               unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct hostent* host;
  char ip[INET6_ADDRSTRLEN];
  int rc, i;

  luv_dns_get_callback(ref);

  rc = ares_parse_aaaa_reply(buf, len, &host, NULL, NULL);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryAAAA");
    luv_acall(ref->L, 1, 0, "dns_after");
    return;
  }

  lua_pushnil(ref->L);
  lua_newtable(ref->L);
  for (i = 0; host->h_addr_list[i]; ++i) {
    uv_inet_ntop(host->h_addrtype, host->h_addr_list[i], ip, sizeof(ip));
    lua_pushstring(ref->L, ip);
    lua_rawseti(ref->L, -2, i+1);
  }

  luv_acall(ref->L, 2, 0, "dns_after");
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryAAAA(lua_State* L)
{
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* req = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_aaaa, queryAAAA_callback, req);
  return 0;
}

static void queryCNAME_callback(void *arg, int status, int timeouts,
                                unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct hostent* host;
  char ip[INET6_ADDRSTRLEN];
  int rc;

  luv_dns_get_callback(ref);

  rc = ares_parse_a_reply(buf, len, &host, NULL, NULL);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryCNAME");
    luv_acall(ref->L, 1, 0, "dns_after");
    return;
  }

  lua_pushnil(ref->L);
  lua_newtable(ref->L);
  uv_inet_ntop(host->h_addrtype, host->h_name, ip, sizeof(ip));
  lua_pushstring(ref->L, ip);
  lua_rawseti(ref->L, -2, 1);

  luv_acall(ref->L, 2, 0, "dns_after");
  luv_dns_ref_cleanup(ref);
}

int luv_dns_queryCNAME(lua_State* L)
{
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* req = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_cname, queryCNAME_callback, req);
  return 0;
}

static void queryMX_callback(void *arg, int status, int timeouts,
                             unsigned char* buf, int len)
{
  luv_dns_ref_t *ref = arg;
  struct ares_mx_reply* start;
  struct ares_mx_reply* cur;
  int rc, i;

  luv_dns_get_callback(ref);

  rc = ares_parse_mx_reply(buf, len, &start);
  if (rc != ARES_SUCCESS) {
    luv_push_ares_async_error(ref->L, rc, "queryMX");
    luv_acall(ref->L, 1, 0, "dns_after");
    return;
  }

  lua_pushnil(ref->L); /* err */
  lua_newtable(ref->L); /* result table */

  for (cur=start, i=1; cur; cur=cur->next, i++) {
    lua_newtable(ref->L);

    lua_pushstring(ref->L, cur->host);
    lua_setfield(ref->L, -2, "exchange");

    lua_pushnumber(ref->L, cur->priority);
    lua_setfield(ref->L, -2, "priority");

    lua_rawseti(ref->L, -2, i);
  }

  ares_free_data(start);

  luv_acall(ref->L, 2, 0, "dns_after");
  luv_dns_ref_cleanup(ref);
}


int luv_dns_queryMX(lua_State* L)
{
  const char* name = luaL_checkstring(L, 1);
  luv_dns_ref_t* req = luv_dns_store_callback(L, 2);
  ares_query(channel, name, ns_c_in, ns_t_mx, queryMX_callback, req);
  return 0;
}

void luv_dns_open(void)
{
  memset(&options, 0, sizeof(options));
  uv_ares_init_options(uv_default_loop(), &channel, &options, 0);
}
