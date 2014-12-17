# Luvit (Lua + libUV + jIT = pure awesomesauce)

--------------------------------------------------------------------------------

# LUVI INTEGRATION IN PROGRESS

[![Linux Build Status](https://travis-ci.org/luvit/luvit.svg?branch=luvi-up)](https://travis-ci.org/luvit/luvit)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/72ccr146fm51k7up/branch/luvi-up?svg=true)](https://ci.appveyor.com/project/racker-buildbot/luvit/branch/luvi-up)

This branch replaces luvit's backend with [luvi][].  This means that most luvit
development is now done in pure lua and doesn't require a build step to test.

First build and/or install luvi and put it somewhere in your path.  This should
work on Windows, OSX, or Linux.  Windows binaries can usually be found at
<https://ci.appveyor.com/project/creationix/luvi/build/artifacts>.

Then grab the `luvi-up` branch of luvit.

```sh
git clone git@github.com:luvit/luvit.git --branch luvi-up
cd luvit
```

Now configure luvi to run this app in dev mode:

```sh
export LUVI_APP=`pwd`/app
```

Or if you're on windows, use `set` to set the `LUVI_APP` environment variable to
point to the `app` subfolder in luvit's clone.

Now, whenever you run luvi, it will act as if the code in `app` was zipped and
appended to it's excutable (it's the bundle).

To actually *build* luvit, run the `make` command which is really just running
luvi with some special flags telling it to bundle the luvit code and create a
new binary.

```sh
LUVI_APP=app LUVI_TARGET=luvit luvi
```

To test your code, use the test target in the makefile or run the
`tests\run.lua` file with luvit.

```sh
make test
```

--------------------------------------------------------------------------------

[![Build Status](https://travis-ci.org/luvit/luvit.svg?branch=master)](https://travis-ci.org/luvit/luvit)

Luvit is an attempt to do something crazy by taking node.js' awesome
architecture and dependencies and seeing how it fits in the Lua language.

This project is still under heavy development, but it's showing promise. In
initial benchmarking with a hello world server, this is between 2 and 4 times
faster than node.js. Version 0.5.0 is the latest release version.

Do you have a question/want to learn more? Make sure to check out the [mailing
list](http://groups.google.com/group/luvit/) and drop by our IRC channel, #luvit
on Freenode.

```lua
-- Load the http library
local HTTP = require("http")

-- Create a simple nodeJS style hello-world server
HTTP.createServer(function (req, res)
  local body = "Hello World\n"
  res:writeHead(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #body
  })
  res:finish(body)
end):listen(8080)

-- Give a friendly message
print("Server listening at http://localhost:8080/")
```

### Building from git

Grab a copy of the source code:

`git clone https://github.com/luvit/luvit.git --recursive`

To use the gyp build system run:

```
cd luvit
git submodule update --init --recursive
./configure
make -C out
tools/build.py test
./out/Debug/luvit
```

To use the Makefile build system (for embedded systems without python)
run:

```
cd luvit
make
make test
./build/luvit
```

## Debugging

Luvit contains an extremely useful debug API. Lua contains a stack which is used
to manipulate the virtual machine and return values to 'C'. It is often very
useful to display this stack to aid in debugging. In fact, this API is
accessible via C or from Lua.

### Stackwalk

```lua
require('_debug').stackwalk(errorString)
```

Displays a backtrace of the current Lua state. Useful when an error happens and
you want to get a call stack.

example output:

```text
Lua stack backtrace: error
    in Lua code at luvit/tests/test-crypto.lua:69 fn()
    in Lua code at luvit/lib/luvit/module.lua:67 myloadfile()
    in Lua code at luvit/lib/luvit/luvit.lua:285 (null)()
    in native code
    in Lua code at luvit/lib/luvit/luvit.lua:185 (null)()
    in native code
    in Lua code at [string "    local path = require('uv_native').execpat..."]:1 (null)()
```

### Stackdump

```lua
require('_debug').stackdump(string)
```

```c
luv_lua_debug_stackdump(L, "a message");
```

Stackdump is extremly useful from within C modules.

### Debugger

```lua
require('_debug').debugger()
```

Supports the following commands:

* quit
* exit
* break
* clear
* clearall
* trace
* bt

The debugger will execute any arbitrary Lua statement by default.

## Embedding

A static library is generated when compiling Luvit. This allows for easy
embedding into other projects. LuaJIT, libuv, and all other dependencies are
included.

```c
#include <string.h>
#include <stdlib.h>
#include <limits.h> /* PATH_MAX */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifndef WIN32
#include <pthread.h>
#endif
#include "uv.h"

#include "luvit.h"
#include "luvit_init.h"
#include "luv.h"

int main(int argc, char *argv[])
{
  lua_State *L;
  uv_loop_t *loop;

  argv = uv_setup_args(argc, argv);

  L = luaL_newstate();
  if (L == NULL) {
    fprintf(stderr, "luaL_newstate has failed\n");
    return 1;
  }

  luaL_openlibs(L);

  loop = uv_default_loop();

#ifdef LUV_EXPORTS
  luvit__suck_in_symbols();
#endif

#ifdef USE_OPENSSL
  luvit_init_ssl();
#endif

  if (luvit_init(L, loop, argc, argv)) {
    fprintf(stderr, "luvit_init has failed\n");
    return 1;
  }

  ... Run a luvit file from memory or disk ...
  ...    or call uv_run ...

  lua_close(L);
  return 0;
}
```

[luvi]: https://github.com/luvit/luvi
