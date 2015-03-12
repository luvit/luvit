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

## Getting Luvit

First make sure you have `lit` [installed](https://github.com/luvit/lit#installing-lit) and in your path.

Then luvit can be built with the `lit make` command using a remote app url.

The latest published lit release of luvit can be built with:

```sh
lit make lit://luvit/luvit
```

If you'd rather test the master branch on github, use:

```sh
lit make github://luvit/luvit
```

Both these commands will create a `luvit` executable in the current directory, put it in your path somewhere.

To test your install run `luvit` to enter the repl.  This has readline-like capabilities implemented in lua and has tab completion of expressions for interactive exploring the runtime.

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

## Hacking on Luvit Core

First you need to clone and build luvit, this is easy and works cross-platform thanks to `Makefile` and `make.bat`.

```sh
git clone https://github.com/luvit/luvit.git
cd luvit
make
```

If you want to test luvit without constantly building, set the magic `LUVI_APP` variable that makes **all** luvi binaries use a certain folder for the app bundle.  This is best done with a bash alias so as to not break other luvi based apps like `lit`.

```sh
alias luvit=LUVI_APP=`pwd`" "luvit
```

Also you can use `lit run` in the luvit root folder.

Always make sure to run `make test` before submitting a PR.

## Binary Modules

Luvit supports FFI and Lua based binary modules. There is a wiki entry
explaining how to manage and include a binary module within a bundled
application. [Publishing Compiled Code][]

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
[Publishing Compiled Code]: https://github.com/luvit/lit/wiki/Publishing-Compiled-Code
