# Luvit 2.0 - Node.JS for the Lua Inventor

[![Linux Build Status](https://travis-ci.org/luvit/luvit.svg?branch=luvi-up)](https://travis-ci.org/luvit/luvit)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/72ccr146fm51k7up/branch/luvi-up?svg=true)](https://ci.appveyor.com/project/racker-buildbot/luvit/branch/luvi-up)

Welcome to the source code for Luvit 2.0.  This repo contains the luvit/luvit metapackage and all luvit/* packages as published to lit.

This collection of packages and modules implementes a node.js style API for the luvi/lit runtime.  It can be used as both a library or a standalone executible.

See the main project webpage for more details. <https://luvit.io/>

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

If you want to test luvit without constantly building, set the magic `LUVI_APP` variable that makes **all** luvi binaries use a certain folder for the app bundle.  This is best done with a bash alias so as to not break other luvi based apps like `lit`.

```sh
alias luvit=LUVI_APP=`pwd`" "luvit
```

Also you can use `lit run` in the luvit root folder.

Always make sure to run `make test` before submitting a PR.

## Notes to Maintainers

 - Use `LUVI_APP=/path/to/luvit luvit` to test changes without rebuilding the binary.
 - To run the test suite, either run `make test` to build a luvit and use that.
 - If you want to test a custom built luvi, run `LUVI_APP=. /path/to/luvi tests/run.lua`
 - There is a wiki page on making new luvit releases at <https://github.com/luvit/luvit/wiki/Making-a-luvit-release>.

The packages in deps live primarily in this repo, but some are duplicated in
luvit/lit to ease `lit` bootstrapping.  Updates can be pushed from either repo
to lit, just make sure to keep them in sync.  One way to do this is to `rm -rf
deps && lit install`.  This will install the latest version of all the
packages from lit.  Check the diff carefully to make sure you're not undoing
any work.  There might have been unpublished changes locally in luvit that
aren't in the lit central database yet.

[Publishing Compiled Code]: https://github.com/luvit/lit/wiki/Publishing-Compiled-Code
