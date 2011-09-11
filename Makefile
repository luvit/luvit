LUADIR=deps/LuaJIT-2.0.0-beta8
UVDIR=deps/uv
HTTPDIR=deps/http-parser

all: luanode webserver

${LUADIR}/src/libluajit.a:
	$(MAKE) -C ${LUADIR}

${UVDIR}/uv.a:
	$(MAKE) -C ${UVDIR}

${HTTPDIR}/http_parser.o:
	make -C ${HTTPDIR} http_parser.o

webserver: webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	$(CC) -o webserver webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o \
	  -I${HTTPDIR} -I${UVDIR}/include -lrt -lm

luanode: luanode.c ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	$(CC) -o luanode luanode.c ${UVDIR}/uv.a ${LUADIR}/src/libluajit.a \
	  -I${UVDIR}/include -I${LUADIR}/src -lm -ldl -lrt

clean:
	make -C ${LUADIR} clean
	make -C ${HTTPDIR} clean
	make -C ${UVDIR} distclean
	rm -f luanode webserver




