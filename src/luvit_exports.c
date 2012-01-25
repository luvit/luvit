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
extern const char **luaJIT_BC_json;
extern const char **luaJIT_BC_luvit;
extern const char **luaJIT_BC_mime;
extern const char **luaJIT_BC_net;
extern const char **luaJIT_BC_path;
extern const char **luaJIT_BC_pipe;
extern const char **luaJIT_BC_process;
extern const char **luaJIT_BC_querystring;
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
extern const char **luaJIT_BC_object;
extern const char **luaJIT_BC_handle;

const void *luvit__suck_in_symbols(void)
{
  luvit_ugly_hack = (const void*)
    (size_t)(const void *)luaJIT_BC_dns +
    (size_t)(const void *)luaJIT_BC_emitter +
    (size_t)(const void *)luaJIT_BC_error +
    (size_t)(const void *)luaJIT_BC_fiber +
    (size_t)(const void *)luaJIT_BC_fs +
    (size_t)(const void *)luaJIT_BC_http +
    (size_t)(const void *)luaJIT_BC_json +
    (size_t)(const void *)luaJIT_BC_luvit +
    (size_t)(const void *)luaJIT_BC_mime +
    (size_t)(const void *)luaJIT_BC_net +
    (size_t)(const void *)luaJIT_BC_path +
    (size_t)(const void *)luaJIT_BC_pipe +
    (size_t)(const void *)luaJIT_BC_process +
    (size_t)(const void *)luaJIT_BC_querystring +
    (size_t)(const void *)luaJIT_BC_repl +
    (size_t)(const void *)luaJIT_BC_request +
    (size_t)(const void *)luaJIT_BC_response +
    (size_t)(const void *)luaJIT_BC_stack +
    (size_t)(const void *)luaJIT_BC_stream +
    (size_t)(const void *)luaJIT_BC_tcp +
    (size_t)(const void *)luaJIT_BC_timer +
    (size_t)(const void *)luaJIT_BC_tty +
    (size_t)(const void *)luaJIT_BC_udp +
    (size_t)(const void *)luaJIT_BC_url +
    (size_t)(const void *)luaJIT_BC_object +
    (size_t)(const void *)luaJIT_BC_handle +
    (size_t)(const void *)luaJIT_BC_utils;

  return luvit_ugly_hack;
}



