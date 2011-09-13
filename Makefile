LUADIR=deps/LuaJIT-2.0.0-beta8
UVDIR=deps/uv
HTTPDIR=deps/http-parser
BUILDDIR=build

all: luanode

webserver: ${BUILDDIR}/webserver

luanode: ${BUILDDIR}/luanode

${LUADIR}/src/libluajit.a:
	$(MAKE) -C ${LUADIR}

${UVDIR}/uv.a:
	$(MAKE) -C ${UVDIR}

${HTTPDIR}/http_parser.o:
	make -C ${HTTPDIR} http_parser.o

#lib/uv.so: src/uv.c


${BUILDDIR}/webserver: src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	mkdir -p ${BUILDDIR}
	$(CC) -o ${BUILDDIR}/webserver src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o \
	  -I${HTTPDIR} -I${UVDIR}/include -lrt -lm

${BUILDDIR}/luanode: src/luanode.c src/luv.c src/lhttp_parser.c ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	mkdir -p ${BUILDDIR}
	$(CC) -o ${BUILDDIR}/luanode src/luanode.c src/luv.c src/lhttp_parser.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${LUADIR}/src/libluajit.a \
	  -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -lm -ldl -lrt

clean:
	make -C ${LUADIR} clean
	make -C ${HTTPDIR} clean
	make -C ${UVDIR} distclean
	rm -rf build




