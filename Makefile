LUADIR=deps/luajit
UVDIR=deps/uv
HTTPDIR=deps/http-parser
YAJLDIR=deps/yajl
BUILDDIR=build
GENDIR=${BUILDDIR}/generated
PREFIX?=/usr/local
BINDIR?=${PREFIX}/bin
INCDIR?=${PREFIX}/include
INCLUDEDIR?=${DESTDIR}${INCDIR}/luvit
OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
ifeq (${OS_NAME},Darwin)
ifeq (${MH_NAME},x86_64)
LDFLAGS=-framework CoreServices -pagezero_size 10000 -image_base 100000000
else
LDFLAGS=-framework CoreServices
endif
else ifeq (${OS_NAME},Linux)
LDFLAGS=-Wl,-E -lrt
endif
# LUAJIT CONFIGURATION #
XCFLAGS=-g
#XCFLAGS+=-DLUAJIT_DISABLE_JIT
XCFLAGS+=-DLUAJIT_ENABLE_LUA52COMPAT
XCFLAGS+=-DLUA_USE_APICHECK
export XCFLAGS
# verbose build
export Q=
MAKEFLAGS+=-e

LUALIBS=${GENDIR}/luvit.o    \
        ${GENDIR}/http.o     \
        ${GENDIR}/url.o      \
        ${GENDIR}/querystring.o \
        ${GENDIR}/request.o  \
        ${GENDIR}/response.o \
        ${GENDIR}/fs.o       \
        ${GENDIR}/dns.o      \
        ${GENDIR}/net.o      \
        ${GENDIR}/process.o  \
        ${GENDIR}/error.o    \
        ${GENDIR}/emitter.o  \
        ${GENDIR}/udp.o      \
        ${GENDIR}/stream.o   \
        ${GENDIR}/tcp.o      \
        ${GENDIR}/pipe.o     \
        ${GENDIR}/tty.o      \
        ${GENDIR}/timer.o    \
        ${GENDIR}/repl.o     \
        ${GENDIR}/fiber.o    \
        ${GENDIR}/mime.o     \
        ${GENDIR}/path.o     \
        ${GENDIR}/stack.o    \
        ${GENDIR}/json.o     \
        ${GENDIR}/utils.o

LUVLIBS=${BUILDDIR}/utils.o          \
        ${BUILDDIR}/luv_fs.o         \
        ${BUILDDIR}/luv_dns.o        \
        ${BUILDDIR}/luv_handle.o     \
        ${BUILDDIR}/luv_udp.o        \
        ${BUILDDIR}/luv_fs_watcher.o \
        ${BUILDDIR}/luv_timer.o      \
        ${BUILDDIR}/luv_process.o    \
        ${BUILDDIR}/luv_stream.o     \
        ${BUILDDIR}/luv_tcp.o        \
        ${BUILDDIR}/luv_pipe.o       \
        ${BUILDDIR}/luv_tty.o        \
        ${BUILDDIR}/luv_misc.o       \
        ${BUILDDIR}/lconstants.o     \
        ${BUILDDIR}/lenv.o           \
        ${BUILDDIR}/lyajl.o          \
        ${BUILDDIR}/lhttp_parser.o

ALLLIBS=${BUILDDIR}/luvit.o       \
        ${LUVLIBS}                \
        ${BUILDDIR}/luv.o         \
        ${LUADIR}/src/libluajit.a \
        ${UVDIR}/uv.a             \
        ${YAJLDIR}/yajl.a         \
        ${HTTPDIR}/http_parser.o  \
        ${LUALIBS}

all: ${BUILDDIR}/luvit

deps: ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${YAJLDIR}/yajl.a

${GENDIR}:
	mkdir -p ${GENDIR}

${LUADIR}/Makefile:
	git submodule update --init ${LUADIR}

${LUADIR}/src/libluajit.a: ${LUADIR}/Makefile
	touch -c ${LUADIR}/src/*.h
	$(MAKE) -C ${LUADIR}

${YAJLDIR}/CMakeLists.txt: 
	git submodule update --init ${YAJLDIR}

${YAJLDIR}/Makefile: deps/Makefile.yajl ${YAJLDIR}/CMakeLists.txt
	cp deps/Makefile.yajl ${YAJLDIR}/Makefile

${YAJLDIR}/yajl.a: ${YAJLDIR}/Makefile
	$(MAKE) -C ${YAJLDIR}

${UVDIR}/Makefile:
	git submodule update --init ${UVDIR}

${UVDIR}/uv.a: ${UVDIR}/Makefile
	$(MAKE) -C ${UVDIR} uv.a

${HTTPDIR}/Makefile:
	git submodule update --init ${HTTPDIR}

${HTTPDIR}/http_parser.o: ${HTTPDIR}/Makefile
	${MAKE} -C ${HTTPDIR} http_parser.o

${GENDIR}/%.c: lib/%.lua deps
	${LUADIR}/src/luajit -b $< $@

${GENDIR}/%.o: ${GENDIR}/%.c
	$(CC) -g -Wall -c $< -o $@

${BUILDDIR}/%.o: src/%.c src/%.h deps
	mkdir -p ${BUILDDIR}
	$(CC) -g -Wall -Werror -c $< -o $@ -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DLUVIT_OS=\"unix\"

${BUILDDIR}/luvit: ${GENDIR} ${ALLLIBS}
	$(CC) -g -o ${BUILDDIR}/luvit ${ALLLIBS} -Wall -lm -ldl -lpthread ${LDFLAGS}

clean:
	${MAKE} -C ${LUADIR} clean
	${MAKE} -C ${HTTPDIR} clean
	${MAKE} -C ${YAJLDIR} clean
	${MAKE} -C ${UVDIR} distclean
	${MAKE} -C examples/native clean
	rm -rf build

install: ${BUILDDIR}/luvit
	mkdir -p ${BINDIR}
	install ${BUILDDIR}/luvit ${DESTDIR}${BINDIR}/luvit
	cp bin/luvit-config.lua ${DESTDIR}${BINDIR}/luvit-config
	chmod +x ${DESTDIR}${BINDIR}/luvit-config
	mkdir -p ${INCLUDEDIR}/luajit
	cp ${LUADIR}/src/lua.h ${INCLUDEDIR}/luajit/
	cp ${LUADIR}/src/lauxlib.h ${INCLUDEDIR}/luajit/
	cp ${LUADIR}/src/luaconf.h ${INCLUDEDIR}/luajit/
	cp ${LUADIR}/src/luajit.h ${INCLUDEDIR}/luajit/
	cp ${LUADIR}/src/lualib.h ${INCLUDEDIR}/luajit/
	mkdir -p ${INCLUDEDIR}/http_parser
	cp ${HTTPDIR}/http_parser.h ${INCLUDEDIR}/http_parser/
	mkdir -p ${INCLUDEDIR}/uv
	cp ${UVDIR}/include/uv.h ${INCLUDEDIR}/uv/
	cp src/*.h ${INCLUDEDIR}/

uninstall deinstall:
	rm -rf ${INCLUDEDIR}
	rm -f ${DESTDIR}${BINDIR}/luvit ${DESTDIR}${BINDIR}/luvit-config

examples/native/vector.luvit: examples/native/vector.c examples/native/vector.h
	${MAKE} -C examples/native

test: examples/native/vector.luvit
	cd tests && ../${BUILDDIR}/luvit runner.lua

.PHONY: test install all
