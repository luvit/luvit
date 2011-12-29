LUADIR=deps/luajit
UVDIR=deps/uv
HTTPDIR=deps/http-parser
BUILDDIR=build
GENDIR=${BUILDDIR}/generated
PREFIX?=/usr/local
BINDIR?=${PREFIX}/bin
INCDIR?=${PREFIX}/include
INCLUDEDIR?=${DESTDIR}${INCDIR}/luvit
ifeq ($(shell uname -sm | sed -e s,x86_64,i386,),Darwin i386)
# force x86-32 on OSX-x86
export CC=gcc -arch i386 
LDFLAGS=-framework CoreServices
# strip is broken in OSX. do not strip it
INSTALL_PROGRAM=install -v
else
# linux
INSTALL_PROGRAM=install -v -s
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
        ${GENDIR}/request.o  \
        ${GENDIR}/response.o \
        ${GENDIR}/fs.o       \
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
        ${GENDIR}/utils.o

LUVLIBS=${BUILDDIR}/utils.o          \
        ${BUILDDIR}/luv_fs.o         \
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
        ${BUILDDIR}/lhttp_parser.o

ALLLIBS=${BUILDDIR}/luvit.o       \
        ${LUVLIBS}                \
        ${BUILDDIR}/luv.o         \
        ${LUADIR}/src/libluajit.a \
        ${UVDIR}/uv.a             \
        ${HTTPDIR}/http_parser.o  \
        ${LUALIBS}

all: ${BUILDDIR}/luvit

deps: ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o

${GENDIR}:
	mkdir -p ${GENDIR}

${LUADIR}/Makefile:
	git submodule update --init ${LUADIR}

${LUADIR}/src/libluajit.a: ${LUADIR}/Makefile
	touch -c ${LUADIR}/src/*.h
	$(MAKE) -C ${LUADIR}

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
	$(CC) -g -Wall -Werror -c $< -o $@ -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DLUVIT_OS=\"unix\"

${BUILDDIR}/luvit: ${GENDIR} ${ALLLIBS}
	$(CC) -g -o ${BUILDDIR}/luvit ${ALLLIBS} -Wall -lm -ldl -lpthread ${LDFLAGS}

clean:
	${MAKE} -C ${LUADIR} clean
	${MAKE} -C ${HTTPDIR} clean
	${MAKE} -C ${UVDIR} distclean
	${MAKE} -C examples/native clean
	rm -rf build

install: ${BUILDDIR}/luvit
	mkdir -p ${BINDIR}
	${INSTALL_PROGRAM} ${BUILDDIR}/luvit ${DESTDIR}${BINDIR}/luvit
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

test: ${BUILDDIR}/luvit examples/native/vector.luvit
	find tests -name "test-*.lua" | while read LINE; do \
		${BUILDDIR}/luvit $$LINE > tests/failed_test.log && \
		rm tests/failed_test.log || cat tests/failed_test.log; \
	done

.PHONY: test install all
