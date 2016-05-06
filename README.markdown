# Luvit 2.0 - Node.JS for the Lua Inventor

[![Linux Build Status](https://travis-ci.org/luvit/luvit.svg?branch=master)](https://travis-ci.org/luvit/luvit)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/72ccr146fm51k7up/branch/master?svg=true)](https://ci.appveyor.com/project/racker-buildbot/luvit/branch/master)
[![#luvit on Freenode](https://img.shields.io/Freenode/%23luvit.png)](https://webchat.freenode.net/?channels=luvit)


Welcome to the source code for Luvit 2.0.  This repo contains the luvit/luvit metapackage and all luvit/* packages as published to [lit][].

This collection of packages and modules implements a node.js style API for the [luvi][]/[lit][] runtime.  It can be used as both a library or a standalone executable.

See the main project webpage for more details. <https://luvit.io/>

## Need Help?

Ask questions here through issues, on irc [#luvit@freenode](irc://chat.freenode.net/luvit) or the [mailing list](https://groups.google.com/forum/#!forum/luvit).

## Binary Modules

Luvit supports FFI and Lua based binary modules. There is a wiki entry
explaining how to manage and include a binary module within a bundled
application. [Publishing Compiled Code][]

## Hacking on Luvit Core

First you need to clone and build luvit, this is easy and works cross-platform thanks to `Makefile` and `make.bat`.

```sh
git clone https://github.com/luvit/luvit.git
cd luvit
make
```

If you want to test luvit without constantly building, use `luvi`.

```sh
luvi . 
```

Always make sure to run `make test` before submitting a PR.

## Notes to Maintainers

 - Use `luvi /path/to/luvit` to test changes without rebuilding the binary.
 - To run the test suite, run `make test` to build a luvit and use that.
 - If you want to test a custom built luvi, run `luvi . -- tests/run.lua`
 - If you want to run a specific test file with a custom built luvi, run `luvi . -- tests/test-<name-of-test>.lua` (e.g. `luvi . -- tests/test-http.lua`)
 - There is a wiki page on making new luvit releases at <https://github.com/luvit/luvit/wiki/Making-a-luvit-release>.

The packages in deps live primarily in this repo, but some are duplicated in
luvit/lit to ease `lit` bootstrapping.  Updates can be pushed from either repo
to lit, just make sure to keep them in sync.  One way to do this is to `rm -rf
deps && lit install`.  This will install the latest version of all the
packages from lit.  Check the diff carefully to make sure you're not undoing
any work.  There might have been unpublished changes locally in luvit that
aren't in the lit central database yet.

[Publishing Compiled Code]: https://github.com/luvit/lit/wiki/Publishing-Compiled-Code
[lit]: https://github.com/luvit/lit/
[luvi]: https://github.com/luvit/luvi/
