
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
    (int)(const void *)luaJIT_BC_dns +
    (int)(const void *)luaJIT_BC_emitter +
    (int)(const void *)luaJIT_BC_fiber +
    (int)(const void *)luaJIT_BC_fs +
    (int)(const void *)luaJIT_BC_http +
    (int)(const void *)luaJIT_BC_luvit +
    (int)(const void *)luaJIT_BC_mime +
    (int)(const void *)luaJIT_BC_net +
    (int)(const void *)luaJIT_BC_path +
    (int)(const void *)luaJIT_BC_pipe +
    (int)(const void *)luaJIT_BC_process +
    (int)(const void *)luaJIT_BC_repl +
    (int)(const void *)luaJIT_BC_request +
    (int)(const void *)luaJIT_BC_response +
    (int)(const void *)luaJIT_BC_stack +
    (int)(const void *)luaJIT_BC_stream +
    (int)(const void *)luaJIT_BC_tcp +
    (int)(const void *)luaJIT_BC_tty +
    (int)(const void *)luaJIT_BC_udp +
    (int)(const void *)luaJIT_BC_url +
    (int)(const void *)luaJIT_BC_utils;

  return luvit_ugly_hack;
}



