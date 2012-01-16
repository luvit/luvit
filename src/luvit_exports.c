
#include <string.h>
#include "luvit.h"

const void *luvit_ugly_hack = NULL;

/* TODO: generate this file */

extern const char **luaJIT_BC_dns;
extern const char **luaJIT_BC_emitter;
extern const char **luaJIT_BC_error;
extern const char **luaJIT_BC_fiber;
extern const char **luaJIT_BC_fs;
extern const char **luaJIT_BC_http;
extern const char **luaJIT_BC_luvit;
extern const char **luaJIT_BC_mime;
extern const char **luaJIT_BC_net;
extern const char **luaJIT_BC_path;
extern const char **luaJIT_BC_pipe;
extern const char **luaJIT_BC_process;
extern const char **luaJIT_BC_repl;
extern const char **luaJIT_BC_request;
extern const char **luaJIT_BC_response;
extern const char **luaJIT_BC_stack;
extern const char **luaJIT_BC_stream;
extern const char **luaJIT_BC_tcp;
extern const char **luaJIT_BC_timer;
extern const char **luaJIT_BC_tty;
extern const char **luaJIT_BC_udp;
extern const char **luaJIT_BC_url;
extern const char **luaJIT_BC_utils;

const void *suck_in_luvit(void)
{
  luvit_ugly_hack = (const void*)
    (size_t)(const void *)luaJIT_BC_dns +
    (size_t)(const void *)luaJIT_BC_emitter +
    (size_t)(const void *)luaJIT_BC_fiber +
    (size_t)(const void *)luaJIT_BC_fs +
    (size_t)(const void *)luaJIT_BC_http +
    (size_t)(const void *)luaJIT_BC_luvit +
    (size_t)(const void *)luaJIT_BC_mime +
    (size_t)(const void *)luaJIT_BC_net +
    (size_t)(const void *)luaJIT_BC_path +
    (size_t)(const void *)luaJIT_BC_pipe +
    (size_t)(const void *)luaJIT_BC_process +
    (size_t)(const void *)luaJIT_BC_repl +
    (size_t)(const void *)luaJIT_BC_request +
    (size_t)(const void *)luaJIT_BC_response +
    (size_t)(const void *)luaJIT_BC_stack +
    (size_t)(const void *)luaJIT_BC_stream +
    (size_t)(const void *)luaJIT_BC_tcp +
    (size_t)(const void *)luaJIT_BC_tty +
    (size_t)(const void *)luaJIT_BC_udp +
    (size_t)(const void *)luaJIT_BC_url +
    (size_t)(const void *)luaJIT_BC_utils;

  return luvit_ugly_hack;
}



