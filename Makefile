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
LDFLAGS=-framework CoreServices -pagezero_size 10000 -image_base 100000000
else
LDFLAGS=-framework CoreServices
endif
else ifeq (${OS_NAME},Linux)
LDFLAGS=-Wl,-E
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

LDFLAGS+=-L${BUILDDIR} -lluvit
LDFLAGS+=${LUADIR}/src/libluajit.a
LDFLAGS+=${UVDIR}/uv.a
LDFLAGS+=${YAJLDIR}/yajl.a
ifeq (${USE_SYSTEM_SSL},1)
CFLAGS+=$(shell pkg-config --cflags openssl) -w
LDFLAGS+=${OPENSSL_LIBS}
else
CFLAGS+=-I${SSLDIR}/openssl/include
LDFLAGS+=${SSLDIR}/libopenssl.a
endif
LDFLAGS+=${ZLIBDIR}/libz.a
LDFLAGS+=-Wall -lm -ldl -lpthread

ifeq (${OS_NAME},Linux)
LDFLAGS+= -lrt
endif

CFLAGS += -DUSE_OPENSSL
CFLAGS += -DL_ENDIAN
CFLAGS += -DOPENSSL_THREADS
CFLAGS += -DPURIFY
CFLAGS += -D_REENTRANT
CFLAGS += -DOPENSSL_NO_ASM
CFLAGS += -DOPENSSL_NO_INLINE_ASM
CFLAGS += -DOPENSSL_NO_RC2
CFLAGS += -DOPENSSL_NO_RC5
CFLAGS += -DOPENSSL_NO_MD4
CFLAGS += -DOPENSSL_NO_HW
CFLAGS += -DOPENSSL_NO_GOST
CFLAGS += -DOPENSSL_NO_CAMELLIA
CFLAGS += -DOPENSSL_NO_CAPIENG
CFLAGS += -DOPENSSL_NO_CMS
CFLAGS += -DOPENSSL_NO_FIPS
CFLAGS += -DOPENSSL_NO_IDEA
CFLAGS += -DOPENSSL_NO_MDC2
CFLAGS += -DOPENSSL_NO_MD2
CFLAGS += -DOPENSSL_NO_SEED
CFLAGS += -DOPENSSL_NO_SOCK

ifeq (${MH_NAME},x86_64)
CFLAGS += -I${SSLDIR}/openssl-configs/x64
else
CFLAGS += -I${SSLDIR}/openssl-configs/ia32
endif

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
        ${BUILDDIR}/lhttp_parser.o

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

${ZLIBDIR}/Makefile:
	git submodule update --init ${ZLIBDIR}

${ZLIBDIR}/libz.a: ${ZLIBDIR}/Makefile
	cd ${ZLIBDIR} && ${CC} -c *.c && \
	$(AR) rvs libz.a *.o

${SSLDIR}/Makefile.openssl:
	git submodule update --init ${SSLDIR}

${SSLDIR}/libopenssl.a: ${SSLDIR}/Makefile.openssl
	$(MAKE) -C ${SSLDIR} -f Makefile.openssl

${BUILDDIR}/%.o: src/%.c ${DEPS}
	mkdir -p ${BUILDDIR}
	$(CC) ${CFLAGS} --std=c89 -D_GNU_SOURCE -g -Wall -Werror -c $< -o $@ \
		-I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api \
		-I${YAJLDIR}/src -I${ZLIBDIR} -I${CRYPTODIR}/src \
		-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 \
		-DUSE_SYSTEM_SSL=${USE_SYSTEM_SSL} \
		-DHTTP_VERSION=\"${HTTP_VERSION}\" \
		-DUV_VERSION=\"${UV_VERSION}\" \
		-DYAJL_VERSIONISH=\"${YAJL_VERSION}\" \
		-DLUVIT_VERSION=\"${VERSION}\" \
		-DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"

${BUILDDIR}/libluvit.a: ${CRYPTODIR}/src/lcrypto.o ${LUVLIBS} ${DEPS}
	$(AR) rvs ${BUILDDIR}/libluvit.a ${LUVLIBS} ${DEPS}

${CRYPTODIR}/Makefile:
	git submodule update --init ${CRYPTODIR}

${CRYPTODIR}/src/lcrypto.o: ${CRYPTODIR}/Makefile
	${CC} -c -o ${CRYPTODIR}/src/lcrypto.o -I${CRYPTODIR}/src/ \
		 -I${LUADIR}/src/ ${CRYPTODIR}/src/lcrypto.c

${BUILDDIR}/luvit: ${BUILDDIR}/libluvit.a ${BUILDDIR}/luvit_main.o ${CRYPTODIR}/src/lcrypto.o
	$(CC) ${CFLAGS} -g -o ${BUILDDIR}/luvit ${BUILDDIR}/luvit_main.o ${BUILDDIR}/libluvit.a \
		${CRYPTODIR}/src/lcrypto.o ${LDFLAGS} 

clean:
	${MAKE} -C ${LUADIR} clean
	${MAKE} -C ${SSLDIR} -f Makefile.openssl clean
	${MAKE} -C ${HTTPDIR} clean
	${MAKE} -C ${YAJLDIR} clean
	${MAKE} -C ${UVDIR} distclean
	${MAKE} -C examples/native clean
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
	cp ${UVDIR}/include/uv.h ${INCDIR}/uv/
	cp src/*.h ${INCDIR}/

bundle: build/luvit ${BUILDDIR}/libluvit.a
	build/luvit tools/bundler.lua
	$(CC) --std=c89 -D_GNU_SOURCE -g -Wall -Werror -DBUNDLE -c src/luvit_exports.c -o bundle/luvit_exports.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -I${YAJLDIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHTTP_VERSION=\"${HTTP_VERSION}\" -DUV_VERSION=\"${UV_VERSION}\" -DYAJL_VERSIONISH=\"${YAJL_VERSION}\" -DLUVIT_VERSION=\"${VERSION}\" -DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"
	$(CC) --std=c89 -D_GNU_SOURCE -g -Wall -Werror -DBUNDLE -c src/luvit_main.c -o bundle/luvit_main.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -I${YAJLDIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHTTP_VERSION=\"${HTTP_VERSION}\" -DUV_VERSION=\"${UV_VERSION}\" -DYAJL_VERSIONISH=\"${YAJL_VERSION}\" -DLUVIT_VERSION=\"${VERSION}\" -DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"
	$(CC) -g -o bundle/luvit ${BUILDDIR}/libluvit.a `ls bundle/*.o` ${LDFLAGS}

test: ${BUILDDIR}/luvit
	cd tests && ../${BUILDDIR}/luvit runner.lua

api: api.markdown

api.markdown: $(wildcard lib/*.lua)
	find lib -name "*.lua" | grep -v "luvit.lua" | sort | xargs -l luvit tools/doc-parser.lua > $@

DIST_DIR?=${HOME}/luvit.io/dist
DIST_NAME=luvit-${VERSION}
DIST_FOLDER=${DIST_DIR}/${VERSION}/${DIST_NAME}
DIST_FILE=${DIST_FOLDER}.tar.gz
tarball:
	rm -rf ${DIST_FOLDER} ${DIST_FILE}
	mkdir -p ${DIST_DIR}
	git clone . ${DIST_FOLDER}
	cp deps/gitmodules.local ${DIST_FOLDER}/.gitmodules
	cd ${DIST_FOLDER} ; git submodule update --init
	find ${DIST_FOLDER} -name ".git*" | xargs rm -r
	rm -rf ${DIST_FOLDER}/deps/zlib
	sed -e 's/^VERSION=.*/VERSION=${VERSION}/' \
            -e 's/^LUAJIT_VERSION=.*/LUAJIT_VERSION=${LUAJIT_VERSION}/' \
            -e 's/^UV_VERSION=.*/UV_VERSION=${UV_VERSION}/' \
            -e 's/^HTTP_VERSION=.*/HTTP_VERSION=${HTTP_VERSION}/' \
            -e 's/^YAJL_VERSION=.*/YAJL_VERSION=${YAJL_VERSION}/' < ${DIST_FOLDER}/Makefile > ${DIST_FOLDER}/Makefile.patched
	mv ${DIST_FOLDER}/Makefile.patched ${DIST_FOLDER}/Makefile
	tar -czf ${DIST_FILE} -C ${DIST_DIR}/${VERSION} ${DIST_NAME}
	rm -rf ${DIST_FOLDER}

.PHONY: test install all api.markdown bundle tarball

