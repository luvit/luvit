#include <string.h>
#include <stdlib.h>

#include "lhttp_parser.h"
#include "http_parser.h"

static inline const char* method_to_str(unsigned short m) {
  switch (m) {
    case HTTP_DELETE:     return "DELETE";
    case HTTP_GET:        return "GET";
    case HTTP_HEAD:       return "HEAD";
    case HTTP_POST:       return "POST";
    case HTTP_PUT:        return "PUT";
    case HTTP_CONNECT:    return "CONNECT";
    case HTTP_OPTIONS:    return "OPTIONS";
    case HTTP_TRACE:      return "TRACE";
    case HTTP_COPY:       return "COPY";
    case HTTP_LOCK:       return "LOCK";
    case HTTP_MKCOL:      return "MKCOL";
    case HTTP_MOVE:       return "MOVE";
    case HTTP_PROPFIND:   return "PROPFIND";
    case HTTP_PROPPATCH:  return "PROPPATCH";
    case HTTP_UNLOCK:     return "UNLOCK";
    case HTTP_REPORT:     return "REPORT";
    case HTTP_MKACTIVITY: return "MKACTIVITY";
    case HTTP_CHECKOUT:   return "CHECKOUT";
    case HTTP_MERGE:      return "MERGE";
    case HTTP_MSEARCH:    return "MSEARCH";
    case HTTP_NOTIFY:     return "NOTIFY";
    case HTTP_SUBSCRIBE:  return "SUBSCRIBE";
    case HTTP_UNSUBSCRIBE:return "UNSUBSCRIBE";
    default:              return "UNKNOWN_METHOD";
  }
}

////////////////////////////////////////////////////////////////////////////////

static struct http_parser_settings lhttp_parser_settings;

static int lhttp_parser_on_message_begin(http_parser *p) {
  lua_State *L = p->data;
  printf("on_message_begin\n");
  return 0;
}

static int lhttp_parser_on_url(http_parser *p, const char *at, size_t length) {
  lua_State *L = p->data;
  printf("on_url %.*s\n", length, at);
  return 0;
}

static int lhttp_parser_on_header_field(http_parser *p, const char *at, size_t length) {
  lua_State *L = p->data;
  printf("on_header_field %.*s\n", length, at);
  return 0;
}

static int lhttp_parser_on_header_value(http_parser *p, const char *at, size_t length) {
  lua_State *L = p->data;
  printf("on_header_value %.*s\n", length, at);
  return 0;
}

static int lhttp_parser_on_headers_complete(http_parser *p) {
  lua_State *L = p->data;
  printf("on_headers_complete\n");

  // METHOD
  if (p->type == HTTP_REQUEST) {
    printf("\tmethod %s\n", method_to_str(p->method));
  }

  // STATUS
  if (p->type == HTTP_RESPONSE) {
    printf("\tstatus_code %d\n", p->status_code);
  }

  // VERSION
  printf("\tversion_major %d\n", p->http_major);
  printf("\tversion_minor %d\n", p->http_minor);

  printf("\tshould_keep_alive %s\n", http_should_keep_alive(p) ? "true": "false");

  printf("\tupgrade %s\n", p->upgrade ? "true": "false");

  return 0;
}

static int lhttp_parser_on_body(http_parser *p, const char *at, size_t length) {
  lua_State *L = p->data;
  printf("on_body %.*s\n", length, at);
  return 0;
}

static int lhttp_parser_on_message_complete(http_parser *p) {
  lua_State *L = p->data;
  printf("on_message_complete\n");
  return 0;
}


////////////////////////////////////////////////////////////////////////////////

// Takes as arguments a string for type and a table for event callbacks
static int lhttp_parser_new (lua_State *L) {

  const char *type = luaL_checkstring(L, 1);
  luaL_checktype(L, 2, LUA_TTABLE);

  http_parser* parser = (http_parser*)lua_newuserdata(L, sizeof(http_parser));

  if (0 == strcmp(type, "request")) {
    http_parser_init(parser, HTTP_REQUEST);
  } else if (0 == strcmp(type, "response")) {
    http_parser_init(parser, HTTP_RESPONSE);
  } else {
    return luaL_argerror(L, 1, "type must be 'request' or 'response'");
  }
  
  // Store the current lua state in the parser's data
  parser->data = L;
  
  // Set the callback table as the userdata's environment
  lua_pushvalue(L, 2);
  lua_setfenv (L, -2);

  // Set the type of the userdata as an lhttp_parser instance
  luaL_getmetatable(L, "lhttp_parser");
  lua_setmetatable(L, -2);

  // return the userdata
  return 1;
}

// execute(parser, buffer, offset, length)
static int lhttp_parser_execute (lua_State *L) {
  http_parser* parser = (http_parser *)luaL_checkudata(L, 1, "lhttp_parser");

  luaL_checktype(L, 2, LUA_TSTRING);
  size_t chunk_len;
  const char *chunk = lua_tolstring(L, 2, &chunk_len);
  
  size_t offset = luaL_checkint(L, 3);
  size_t length = luaL_checkint(L, 4);
  
  luaL_argcheck(L, offset < chunk_len, 3, "Offset is out of bounds");
  luaL_argcheck(L, offset + length <= chunk_len, 4,  "Length extends beyond end of chunk");

  size_t nparsed = http_parser_execute(parser, &lhttp_parser_settings, chunk + offset, length);

  lua_pushnumber(L, nparsed);
  return 1;
}

static int lhttp_parser_finish (lua_State *L) {
  http_parser* parser = (http_parser *)luaL_checkudata(L, 1, "lhttp_parser");
  // TODO: Implement
  return 0;
}

static int lhttp_parser_reinitialize (lua_State *L) {
  http_parser* parser = (http_parser *)luaL_checkudata(L, 1, "lhttp_parser");
  // TODO: Implement
  return 0;
}

////////////////////////////////////////////////////////////////////////////////

static const struct luaL_Reg lhttp_parser_f [] = {
  {"new", lhttp_parser_new},
  {NULL, NULL}
};

static const struct luaL_Reg lhttp_parser_m [] = {
  {"execute", lhttp_parser_execute},
  {"finish", lhttp_parser_finish},
  {"reinitialize", lhttp_parser_reinitialize},
  {NULL, NULL}
};

LUALIB_API int luaopen_http_parser (lua_State *L) {

  // This needs to be done sometime?
  lhttp_parser_settings.on_message_begin    = lhttp_parser_on_message_begin;
  lhttp_parser_settings.on_url              = lhttp_parser_on_url;
  lhttp_parser_settings.on_header_field     = lhttp_parser_on_header_field;
  lhttp_parser_settings.on_header_value     = lhttp_parser_on_header_value;
  lhttp_parser_settings.on_headers_complete = lhttp_parser_on_headers_complete;
  lhttp_parser_settings.on_body             = lhttp_parser_on_body;
  lhttp_parser_settings.on_message_complete = lhttp_parser_on_message_complete;

  // Set up our Lua module
  luaL_newmetatable(L, "lhttp_parser");
  /* metatable.__index = metatable */
  lua_pushvalue(L, -1); /* duplicates the metatable */
  lua_setfield(L, -2, "__index");
  
  luaL_register(L, NULL, lhttp_parser_m);
  luaL_register(L, "http_parser", lhttp_parser_f);

  // Stick version info on the http_parser table
  lua_pushnumber(L, HTTP_PARSER_VERSION_MAJOR);
  lua_setfield(L, -2, "VERSION_MAJOR");
  lua_pushnumber(L, HTTP_PARSER_VERSION_MINOR);
  lua_setfield(L, -2, "VERSION_MINOR");

  return 1;
}

