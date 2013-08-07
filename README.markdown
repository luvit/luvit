# Welcome to lev -- Lua for Event-Based IO

Forked from the Luvit project, lev focuses on making Event-Based IO as fast
as possible using libuv and adding a fast buffer object on top of Mike Pall's LuaJIT.

All IO will depend on this fast buffer object,
making moving data from pipe-to-pipe as effortlessly as possible.

Unlike Python, Lua traditionally does not have a core-library.
We believe that this lack of a core-library will allow us easily incorporate fast IO.

We have just begun initial development in late August of 2012.
At the moment development is being lead from Japan.

Join us on IRC at #lev on freenode.net

Many thanks to the initial luvit team,
those who have worked on libuv and of course Mike Pall for LuaJIT.


### Building from git

Grab a copy of the source code:

`git clone https://github.com/connectFree/lev.git --recursive`

To use the gyp build system run:

```
cd lev
./configure
make -C out
tools/build.py test
./out/Debug/luvit
```

To use the Makefile build system (for embedded systems without python)
run:

```
cd lev
make
make test
./build/luvit
```

