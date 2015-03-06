# Luvit 2.0 - Node.JS for the Lua Inventor

Luvit 2.0 is a work in progress.

[![Linux Build Status](https://travis-ci.org/luvit/luvit.svg?branch=luvi-up)](https://travis-ci.org/luvit/luvit)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/72ccr146fm51k7up/branch/luvi-up?svg=true)](https://ci.appveyor.com/project/racker-buildbot/luvit/branch/luvi-up)

The original luvit (started 2011 by [Tim Caswell][]) was a node.js-like
programming environment, but using Luajit instead of V8. This meant a
change in scripting language and a huge change in memory overhead. Speed
between node and luvit was on the same order of magnatude with V8 being
faster sometimes and Luajit faster sometimes. But memory was far more
efficient in luvit. A small node.js program used about 20 times more
memory than a similar luvit program. Luvit found it's niche in places
like [cloud monitoring][] and scripting on slower devices like Raspberry
PIs. It had nearly identical APIs to node and thus was easy to learn for
developers looking for something like node, but less memory hungry.

Luvit 2.0 is a reboot of this idea but far more flexible and
configurable. The new system consists of many parts that can be used
with or without the new luvit framework.

 - [luv][] - New [libUV][] bindings for [Lua][] and [Luajit][].
 - [luvi][] - Pre-compiled [luajit][] + [luv][] + [openssl][] + [zlib][] with zip asset bundling and self-executing apps.
 - [lit][] - The **L**uvit **I**nvention **T**oolkit is a multi-tool
   for building apps, running apps, installing, publishing, and
   serving libraries and apps.  Contains [luvi][] and can embed it in
   new apps.

These three projects offer layers of abstraction and control.  You can
use [luv][] standalone with any lua based runtime.  You can build apps
with [luvi][], which includes [luv][], without using [lit][] or Luvit.
The [lit][] tool embeds [luvi][] and adds higher-level commands and
workflows.

Luvit 2.0 is one more layer on top of this that implements the
[node.js][] [APIs](http://nodejs.org/api/) in lua as a collection of
standalone [lit libraries][].  Luvit can be used several different
ways from lit.


## Luvit 2.0 the Framework

You can use luvit as a metapackage that includes the luvit runtime as
a library as well as including all the luvit standard library as
recursive dependencies to your app.  Simply declare `luvit/luvit` as a
dependency to your lit app and use the luvit library in your
`main.lua` and your standalone executable will live inside a luvit
style environment.

A sample `package.lua` that includes luvit might look like the
following:

```lua
return {
  name = "my-cool-app",
  version = "1.2.3",
  dependencies = {
    "luvit/luvit@2.0.0",
    "creationix/git@1.2.3",
  }
}
```

And the luvit bootstrap in your app's `main.lua` will look something
like:

```lua
-- Bootstrap the require system
local luvi = require('luvi')
luvi.bundle.register('require', "deps/require.lua")
local require = require('require')("bundle:main.lua")

-- Create a luvit powered main
return require('luvit')(function (...)
  -- Your app main logic starts here
end, ...)
```

Then when you build your app with `lit make`, luvit and all it's
libraries will be included in your app.  Also if you install your
app's deps to disk using `lit install`, luvit and all it's deps will
be included in the `deps` folder.

```sh
~/my-cool-app $ lit make
~/my-cool-app $ ./my-cool-app
```

You app will have it's own custom main, but will have all the same
builtins and globals as luvit (plus whatever other globals and
builtins you added).

## Luvit 2.0 the Platform

You can build the `luvit/luvit` metapackage as an app directly to
create the `luvit` command-line tool that mimics the `node` tool and
lets you run arbitrary lua scripts.

```sh
curl -L https://github.com/luvit/luvit/archive/luvi-up.zip > luvit.zip
lit make luvit.zip
sudo install luvit /usr/local/bin
luvit
```

This works much like the original luvit platform.

## Luvit 2.0 the Library

The individual packages that make up the luvit 2.0 metapackage can be
used on their own without buying into the whole ecosystem.  Perhaps
you love the pretty-printer and and advanced readline repl but abhor
callbacks and want to use coroutines instead.  Just mix and match
luvit libraries with other lit libraries in your app or library.  Each
component of the luvit metapackage can be used directly and will
automatically pull in any inter-dependencies it needs.

For example, the `creationix/rye` app uses parts of luvit, but not
it's globals and full set of modules.

```lua
return {
  name = "creationix/rye",
  private = true,
  version = "0.0.1",
  dependencies = {
    "luvit/require@0.2.1",
    "luvit/http-codec@0.1.4",
    "luvit/pretty-print@0.1.0",
    "luvit/json@0.1.0",
    "creationix/git@0.1.1",
    "creationix/hex-bin@1.0.0",
    "creationix/coro-tcp@1.0.4",
    "creationix/coro-fs@1.2.3",
    "creationix/coro-wrapper@0.1.0",
  },
}
```

[cloud monitoring]: https://github.com/virgo-agent-toolkit
[Tim Caswell]: https://github.com/creationix
[libuv]: http://docs.libuv.org/en/v1.x/
[luvi]: https://github.com/luvit/luvi
[luv]: https://github.com/luvit/luv
[lit]: https://github.com/luvit/lit
[lit libraries]: http://lit.luvit.io/packages/luvit
[lua]: http://www.lua.org/
[luajit]: http://luajit.org/
[openssl]: https://www.openssl.org/
[zlib]: http://www.zlib.net/
[node.js]: http://nodejs.org/

--------------------------------------------------------------------------------

# LUVI INTEGRATION IN PROGRESS

This branch replaces luvit's backend with [luvi][]. This means that most
luvit development is now done in pure lua and doesn't require a build
step to test.

First build and/or install luvi and put it somewhere
in your path. This should work on Windows, OSX, or
Linux. Windows binaries can usually be found at
<https://ci.appveyor.com/project/racker-buildbot/luvit/build/artifacts>.

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
