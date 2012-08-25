VERSION=$(shell git describe --tags)
LUADIR=deps/luajit
LUAJIT_VERSION=$(shell git --git-dir ${LUADIR}/.git describe --tags)
YAJLDIR=deps/yajl
YAJL_VERSION=$(shell git --git-dir ${YAJLDIR}/.git describe --tags)
UVDIR=deps/uv
UV_VERSION=$(shell git --git-dir ${UVDIR}/.git describe --all --long | cut -f 3 -d -)
HTTPDIR=deps/http-parser
HTTP_VERSION=$(shell git --git-dir ${HTTPDIR}/.git describe --tags)
ZLIBDIR=deps/zlib
SSLDIR=deps/openssl
BUILDDIR=build
CRYPTODIR=deps/luacrypto

PREFIX?=/usr/local
BINDIR?=${DESTDIR}${PREFIX}/bin
INCDIR?=${DESTDIR}${PREFIX}/include/luvit
LIBDIR?=${DESTDIR}${PREFIX}/lib/luvit

OPENSSL_LIBS=$(shell pkg-config openssl --libs 2> /dev/null)
ifeq (${OPENSSL_LIBS},)
USE_SYSTEM_SSL?=0
else
USE_SYSTEM_SSL?=1
endif

OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
ifeq (${OS_NAME},Darwin)
ifeq (${MH_NAME},x86_64)
LDFLAGS+=-framework CoreServices -pagezero_size 10000 -image_base 100000000
else
LDFLAGS+=-framework CoreServices
endif
else ifeq (${OS_NAME},Linux)
LDFLAGS+=-Wl,-E
endif
# LUAJIT CONFIGURATION #
#XCFLAGS=-g
#XCFLAGS+=-DLUAJIT_DISABLE_JIT
XCFLAGS+=-DLUAJIT_ENABLE_LUA52COMPAT
#XCFLAGS+=-DLUA_USE_APICHECK
export XCFLAGS
# verbose build
export Q=
MAKEFLAGS+=-e

LDFLAGS+=-L${BUILDDIR}
LIBS += -lluvit \
	${ZLIBDIR}/libz.a \
	${YAJLDIR}/yajl.a \
	${UVDIR}/uv.a \
	${LUADIR}/src/libluajit.a \
	-lm -ldl -lpthread
ifeq (${USE_SYSTEM_SSL},1)
CFLAGS+=-Wall -w
CPPFLAGS+=$(shell pkg-config --cflags openssl)
LIBS+=${OPENSSL_LIBS}
else
CPPFLAGS+=-I${SSLDIR}/openssl/include
LIBS+=${SSLDIR}/libopenssl.a
endif

ifeq (${OS_NAME},Linux)
LIBS+=-lrt
endif

CPPFLAGS += -DUSE_OPENSSL
CPPFLAGS += -DL_ENDIAN
CPPFLAGS += -DOPENSSL_THREADS
CPPFLAGS += -DPURIFY
CPPFLAGS += -D_REENTRANT
CPPFLAGS += -DOPENSSL_NO_ASM
CPPFLAGS += -DOPENSSL_NO_INLINE_ASM
CPPFLAGS += -DOPENSSL_NO_RC2
CPPFLAGS += -DOPENSSL_NO_RC5
CPPFLAGS += -DOPENSSL_NO_MD4
CPPFLAGS += -DOPENSSL_NO_HW
CPPFLAGS += -DOPENSSL_NO_GOST
CPPFLAGS += -DOPENSSL_NO_CAMELLIA
CPPFLAGS += -DOPENSSL_NO_CAPIENG
CPPFLAGS += -DOPENSSL_NO_CMS
CPPFLAGS += -DOPENSSL_NO_FIPS
CPPFLAGS += -DOPENSSL_NO_IDEA
CPPFLAGS += -DOPENSSL_NO_MDC2
CPPFLAGS += -DOPENSSL_NO_MD2
CPPFLAGS += -DOPENSSL_NO_SEED
CPPFLAGS += -DOPENSSL_NO_SOCK

ifeq (${MH_NAME},x86_64)
CPPFLAGS += -I${SSLDIR}/openssl-configs/x64
else
CPPFLAGS += -I${SSLDIR}/openssl-configs/ia32
endif

LUVLIBS=${BUILDDIR}/utils.o          \
        ${BUILDDIR}/luv_fs.o         \
        ${BUILDDIR}/luv_dns.o        \
        ${BUILDDIR}/luv_debug.o      \
        ${BUILDDIR}/luv_handle.o     \
        ${BUILDDIR}/luv_udp.o        \
        ${BUILDDIR}/luv_fs_watcher.o \
        ${BUILDDIR}/luv_timer.o      \
        ${BUILDDIR}/luv_process.o    \
        ${BUILDDIR}/luv_stream.o     \
        ${BUILDDIR}/luv_tcp.o        \
        ${BUILDDIR}/luv_tls.o        \
        ${BUILDDIR}/luv_tls_conn.o   \
        ${BUILDDIR}/luv_pipe.o       \
        ${BUILDDIR}/luv_tty.o        \
        ${BUILDDIR}/luv_misc.o       \
        ${BUILDDIR}/luv.o            \
        ${BUILDDIR}/luvit_init.o     \
        ${BUILDDIR}/lconstants.o     \
        ${BUILDDIR}/lenv.o           \
        ${BUILDDIR}/lyajl.o          \
        ${BUILDDIR}/los.o            \
        ${BUILDDIR}/luv_zlib.o       \
        ${BUILDDIR}/lhttp_parser.o   \
        ${BUILDDIR}/luv_buffer.o

DEPS=${LUADIR}/src/libluajit.a \
     ${YAJLDIR}/yajl.a         \
     ${UVDIR}/uv.a             \
     ${ZLIBDIR}/libz.a         \
     ${HTTPDIR}/http_parser.o

ifeq (${USE_SYSTEM_SSL},0)
DEPS+=${SSLDIR}/libopenssl.a
endif

all: ${BUILDDIR}/luvit

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
	rm -rf ${YAJLDIR}/src/yajl
	cp -r ${YAJLDIR}/src/api ${YAJLDIR}/src/yajl
	$(MAKE) -C ${YAJLDIR}

${UVDIR}/Makefile:
	git submodule update --init ${UVDIR}

${UVDIR}/uv.a: ${UVDIR}/Makefile
	$(MAKE) -C ${UVDIR} uv.a

${HTTPDIR}/Makefile:
	git submodule update --init ${HTTPDIR}

${HTTPDIR}/http_parser.o: ${HTTPDIR}/Makefile
	$(MAKE) -C ${HTTPDIR} http_parser.o

${ZLIBDIR}/zlib.gyp:
	git submodule update --init ${ZLIBDIR}

${ZLIBDIR}/libz.a: ${ZLIBDIR}/zlib.gyp
	cd ${ZLIBDIR} && ${CC} -c *.c && \
	$(AR) rvs libz.a *.o

${SSLDIR}/Makefile.openssl:
	git submodule update --init ${SSLDIR}

${SSLDIR}/libopenssl.a: ${SSLDIR}/Makefile.openssl
	$(MAKE) -C ${SSLDIR} -f Makefile.openssl

${BUILDDIR}/%.o: src/%.c ${DEPS}
	mkdir -p ${BUILDDIR}
	$(CC) ${CPPFLAGS} ${CFLAGS} --std=c89 -D_GNU_SOURCE -g -Wall -Werror -c $< -o $@ \
		-I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api \
		-I${YAJLDIR}/src -I${ZLIBDIR} -I${CRYPTODIR}/src \
		-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 \
		-DUSE_SYSTEM_SSL=${USE_SYSTEM_SSL} \
		-DHTTP_VERSION=\"${HTTP_VERSION}\" \
		-DUV_VERSION=\"${UV_VERSION}\" \
		-DYAJL_VERSIONISH=\"${YAJL_VERSION}\" \
		-DLUVIT_VERSION=\"${VERSION}\" \
		-DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"

${BUILDDIR}/libluvit.a: ${CRYPTODIR}/Makefile ${LUVLIBS} ${DEPS}
	$(AR) rvs ${BUILDDIR}/libluvit.a ${LUVLIBS} ${DEPS}

${CRYPTODIR}/Makefile:
	git submodule update --init ${CRYPTODIR}

${CRYPTODIR}/src/lcrypto.o: ${CRYPTODIR}/Makefile
	${CC} ${CPPFLAGS} -c -o ${CRYPTODIR}/src/lcrypto.o -I${CRYPTODIR}/src/ \
		 -I${LUADIR}/src/ ${CRYPTODIR}/src/lcrypto.c

${BUILDDIR}/luvit: ${BUILDDIR}/libluvit.a ${BUILDDIR}/luvit_main.o ${CRYPTODIR}/src/lcrypto.o
	$(CC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -g -o ${BUILDDIR}/luvit ${BUILDDIR}/luvit_main.o ${BUILDDIR}/libluvit.a \
		${CRYPTODIR}/src/lcrypto.o ${LIBS}

clean:
	${MAKE} -C ${LUADIR} clean
	${MAKE} -C ${SSLDIR} -f Makefile.openssl clean
	${MAKE} -C ${HTTPDIR} clean
	${MAKE} -C ${YAJLDIR} clean
	${MAKE} -C ${UVDIR} distclean
	${MAKE} -C examples/native clean
	-rm ${ZLIBDIR}/*.o
	-rm ${CRYPTODIR}/src/lcrypto.o
	rm -rf build bundle

install: all
	mkdir -p ${BINDIR}
	install ${BUILDDIR}/luvit ${BINDIR}/luvit
	mkdir -p ${LIBDIR}
	cp lib/luvit/*.lua ${LIBDIR}
	mkdir -p ${INCDIR}/luajit
	cp ${LUADIR}/src/lua.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/lauxlib.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/luaconf.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/luajit.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/lualib.h ${INCDIR}/luajit/
	mkdir -p ${INCDIR}/http_parser
	cp ${HTTPDIR}/http_parser.h ${INCDIR}/http_parser/
	mkdir -p ${INCDIR}/uv
	cp -r ${UVDIR}/include/* ${INCDIR}/uv/
	cp src/*.h ${INCDIR}/

uninstall:
	test -f ${BINDIR}/luvit && rm -f ${BINDIR}/luvit
	test -d ${LIBDIR} && rm -rf ${LIBDIR}
	test -d ${INCDIR} && rm -rf ${INCDIR}

bundle: bundle/luvit

bundle/luvit: build/luvit ${BUILDDIR}/libluvit.a
	build/luvit tools/bundler.lua
	$(CC) --std=c89 -D_GNU_SOURCE -g -Wall -Werror -DBUNDLE -c src/luvit_exports.c -o bundle/luvit_exports.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -I${YAJLDIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHTTP_VERSION=\"${HTTP_VERSION}\" -DUV_VERSION=\"${UV_VERSION}\" -DYAJL_VERSIONISH=\"${YAJL_VERSION}\" -DLUVIT_VERSION=\"${VERSION}\" -DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"
	$(CC) --std=c89 -D_GNU_SOURCE -g -Wall -Werror -DBUNDLE -c src/luvit_main.c -o bundle/luvit_main.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -I${YAJLDIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHTTP_VERSION=\"${HTTP_VERSION}\" -DUV_VERSION=\"${UV_VERSION}\" -DYAJL_VERSIONISH=\"${YAJL_VERSION}\" -DLUVIT_VERSION=\"${VERSION}\" -DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"
	$(CC) ${LDFLAGS} -g -o bundle/luvit ${BUILDDIR}/libluvit.a `ls bundle/*.o` ${LIBS} ${CRYPTODIR}/src/lcrypto.o

# Test section

test: test-lua test-install test-uninstall

test-lua: ${BUILDDIR}/luvit
	cd tests && ../${BUILDDIR}/luvit runner.lua

ifeq ($(MAKECMDGOALS),test)
DESTDIR=test_install
endif

test-install: install
	test -f ${BINDIR}/luvit
	test -d ${INCDIR}
	test -d ${LIBDIR}

test-uninstall: uninstall
	test ! -f ${BINDIR}/luvit
	test ! -d ${INCDIR}
	test ! -d ${LIBDIR}

api: api.markdown

api.markdown: $(wildcard lib/*.lua)
	find lib -name "*.lua" | grep -v "luvit.lua" | sort | xargs -l luvit tools/doc-parser.lua > $@

DIST_DIR?=${HOME}/luvit.io/dist
DIST_NAME=luvit-${VERSION}
DIST_FOLDER=${DIST_DIR}/${VERSION}/${DIST_NAME}
DIST_FILE=${DIST_FOLDER}.tar.gz
dist_build:
	sed -e 's/^VERSION=.*/VERSION=${VERSION}/' \
            -e 's/^LUAJIT_VERSION=.*/LUAJIT_VERSION=${LUAJIT_VERSION}/' \
            -e 's/^UV_VERSION=.*/UV_VERSION=${UV_VERSION}/' \
            -e 's/^HTTP_VERSION=.*/HTTP_VERSION=${HTTP_VERSION}/' \
            -e 's/^YAJL_VERSION=.*/YAJL_VERSION=${YAJL_VERSION}/' < Makefile > Makefile.dist
	sed -e 's/LUVIT_VERSION=".*/LUVIT_VERSION=\"${VERSION}\"'\'',/' \
            -e 's/LUAJIT_VERSION=".*/LUAJIT_VERSION=\"${LUAJIT_VERSION}\"'\'',/' \
            -e 's/UV_VERSION=".*/UV_VERSION=\"${UV_VERSION}\"'\'',/' \
            -e 's/HTTP_VERSION=".*/HTTP_VERSION=\"${HTTP_VERSION}\"'\'',/' \
            -e 's/YAJL_VERSIONISH=".*/YAJL_VERSIONISH=\"${YAJL_VERSION}\"'\'',/' < luvit.gyp > luvit.gyp.dist

tarball: dist_build
	rm -rf ${DIST_FOLDER} ${DIST_FILE}
	mkdir -p ${DIST_DIR}
	git clone . ${DIST_FOLDER}
	cp deps/gitmodules.local ${DIST_FOLDER}/.gitmodules
	cd ${DIST_FOLDER} ; git submodule update --init
	find ${DIST_FOLDER} -name ".git*" | xargs rm -r
	mv Makefile.dist ${DIST_FOLDER}/Makefile
	mv luvit.gyp.dist ${DIST_FOLDER}/luvit.gyp
	tar -czf ${DIST_FILE} -C ${DIST_DIR}/${VERSION} ${DIST_NAME}
	rm -rf ${DIST_FOLDER}

.PHONY: test install uninstall all api.markdown bundle tarball

