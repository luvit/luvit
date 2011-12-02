LUADIR=deps/luajit
UVDIR=deps/uv
HTTPDIR=deps/http-parser
BUILDDIR=build
GENDIR=${BUILDDIR}/generated
INSTALL_PROGRAM=install -s -v
DESTDIR?=/
PREFIX?=/usr/local
BINDIR?=${PREFIX}/bin
ifeq ($(shell uname -sm | sed -e s,x86_64,i386,),Darwin i386)
# force x86-32 on OSX-x86
export CC=gcc -arch i386 
LDFLAGS=-framework CoreServices
MAKEFLAGS+=-e
else
# linux
LDFLAGS=-Wl,-E -lrt
endif

LUALIBS=${GENDIR}/luvit.o    \
        ${GENDIR}/http.o     \
        ${GENDIR}/url.o      \
        ${GENDIR}/request.o  \
        ${GENDIR}/response.o \
        ${GENDIR}/fs.o       \
        ${GENDIR}/process.o  \
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

${LUADIR}/src/libluajit.a:
	git submodule update --init ${LUADIR}
	[ -e deps/luajit/src/Makefile.orig ] && \
	mv deps/luajit/src/Makefile deps/luajit/src/Makefile.orig && \
	sed -e "s/#XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/" \
		-e "s/#XCFLAGS+= -DLUA_USE_APICHECK/XCFLAGS+= -DLUA_USE_APICHECK/" \
		< deps/luajit/src/Makefile.orig > deps/luajit/src/Makefile
	$(MAKE) -C ${LUADIR}

${UVDIR}/uv.a:
	git submodule update --init ${UVDIR}
	$(MAKE) -C ${UVDIR} uv.a

${HTTPDIR}/http_parser.o:
	git submodule update --init ${HTTPDIR}
	${MAKE} -C ${HTTPDIR} http_parser.o

${GENDIR}/%.c: lib/%.lua deps
	${LUADIR}/src/luajit -b $< $@

${GENDIR}/%.o: ${GENDIR}/%.c
	$(CC) -Wall -c $< -o $@

${BUILDDIR}/%.o: src/%.c src/%.h deps
	mkdir -p ${BUILDDIR}
	$(CC) -Wall -Werror -c $< -o $@ -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

${BUILDDIR}/luvit: ${GENDIR} ${ALLLIBS}
	$(CC) -o ${BUILDDIR}/luvit ${ALLLIBS} -Wall -lm -ldl -lpthread ${LDFLAGS}

clean:
	${MAKE} -C ${LUADIR} clean
	${MAKE} -C ${HTTPDIR} clean
	${MAKE} -C ${UVDIR} distclean
	rm -rf build

install: ${BUILDDIR}/luvit
	mkdir -p ${DESTDIR}/${BINDIR}
	${INSTALL_PROGRAM} ${BUILDDIR}/luvit ${DESTDIR}/${BINDIR}/luvit

examples/native/vector.luvit: examples/native/vector.c examples/native/vector.h
	${MAKE} -C examples/native

test: ${BUILDDIR}/luvit examples/native/vector.luvit
	find tests -name "test-*.lua" | while read LINE; do \
		${BUILDDIR}/luvit $$LINE > tests/failed_test.log && \
		rm tests/failed_test.log || cat tests/failed_test.log; \
	done

.PHONY: test install all
