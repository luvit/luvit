LUADIR=deps/luajit
UVDIR=deps/uv
HTTPDIR=deps/http-parser
BUILDDIR=build
BUILDDIR_LIBLUV=build/libluv
GENDIR=${BUILDDIR}/generated

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
        ${GENDIR}/utils.o

LUVLIBS=${BUILDDIR_LIBLUV}/utils.o          \
        ${BUILDDIR_LIBLUV}/luv.o         \
        ${BUILDDIR_LIBLUV}/luv_fs.o         \
        ${BUILDDIR_LIBLUV}/luv_handle.o     \
        ${BUILDDIR_LIBLUV}/luv_udp.o        \
        ${BUILDDIR_LIBLUV}/luv_fs_watcher.o \
        ${BUILDDIR_LIBLUV}/luv_timer.o      \
        ${BUILDDIR_LIBLUV}/luv_process.o    \
        ${BUILDDIR_LIBLUV}/luv_stream.o     \
        ${BUILDDIR_LIBLUV}/luv_tcp.o        \
        ${BUILDDIR_LIBLUV}/luv_pipe.o       \
        ${BUILDDIR_LIBLUV}/luv_tty.o        \
        ${BUILDDIR_LIBLUV}/luv_misc.o       \
        ${BUILDDIR_LIBLUV}/lconstants.o     \
        ${BUILDDIR_LIBLUV}/lenv.o           \
        ${BUILDDIR_LIBLUV}/lhttp_parser.o

ALLLIBS=${BUILDDIR}/luvit.o       \
        ${BUILDDIR_LIBLUV}/libluv.a         \
        ${LUADIR}/src/libluajit.a \
        ${UVDIR}/uv.a             \
        ${HTTPDIR}/http_parser.o  \
        ${LUALIBS}

all: ${BUILDDIR}/luvit

deps: ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${BUILDDIR_LIBLUV}/libluv.a 

${GENDIR}:
	mkdir -p ${GENDIR}/libluv

${LUADIR}/src/libluajit.a:
	git submodule update --init ${LUADIR}
	sed -e "s/#XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT/" -i deps/luajit/src/Makefile
	sed -e "s/#XCFLAGS+= -DLUA_USE_APICHECK/XCFLAGS+= -DLUA_USE_APICHECK/" -i deps/luajit/src/Makefile
	$(MAKE) -C ${LUADIR}

${UVDIR}/uv.a:
	git submodule update --init ${UVDIR}
	$(MAKE) -C ${UVDIR} uv.a

${HTTPDIR}/http_parser.o:
	git submodule update --init ${HTTPDIR}
	make -C ${HTTPDIR} http_parser.o

${GENDIR}/%.c: lib/%.lua deps
	${LUADIR}/src/luajit -b $< $@

${GENDIR}/%.o: ${GENDIR}/%.c
	$(CC) -Wall -c $< -o $@

${BUILDDIR_LIBLUV}/%.o: libluv/%.c libluv/%.h deps
	mkdir -p ${BUILDDIR_LIBLUV}
	$(CC) -Wall -Werror -c $< -o $@ -Ilibluv -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

${BUILDDIR_LIBLUV}/libluv.a: ${LUVLIBS}
	$(AR) rvs ${BUILDDIR_LIBLUV}/libluv.a ${BUILDDIR_LIBLUV}/*.o

${BUILDDIR}/%.o: src/%.c src/%.h deps
	mkdir -p ${BUILDDIR}
	$(CC) -Wall -Werror -c $< -o $@ -Ilibluv -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

${BUILDDIR}/luvit: ${GENDIR} ${ALLLIBS}
	$(CC) -o ${BUILDDIR}/luvit ${ALLLIBS} -Wall -lm -ldl -lrt -lpthread -Wl,-E

clean:
	make -C ${LUADIR} clean
	make -C ${HTTPDIR} clean
	make -C ${UVDIR} distclean
	rm -rf build

install: ${BUILDDIR}/luvit
	install ${BUILDDIR}/luvit -s -v /usr/local/bin/luvit

