#ifndef LCONSTANTS
#define LCONSTANTS

#include <uv.h>

#include <errno.h>
#if !defined(_MSC_VER)
#include <unistd.h>
#endif
#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>

#if defined(__MINGW32__) || defined(_MSC_VER)
# include <platform_win32.h>
#endif

#if HAVE_OPENSSL
# include <openssl/ssl.h>
#endif

#include "lua.h"
#include "lauxlib.h"
#include "utils.h"

LUALIB_API int luaopen_constants(lua_State *L);

#endif
