LUADIR=deps/luajit
UVDIR=deps/uv
HTTPDIR=deps/http-parser
BUILDDIR=build

all: luvit

webserver: ${BUILDDIR}/webserver

luvit: ${BUILDDIR}/luvit

${LUADIR}/src/libluajit.a:
	$(MAKE) -C ${LUADIR}

${UVDIR}/uv.a:
	$(MAKE) -C ${UVDIR}

${HTTPDIR}/http_parser.o:
	make -C ${HTTPDIR} http_parser.o

generated:
	ln -sf ${LUADIR}/lib jit
	mkdir -p generated

generated/%.c: lib/%.lua ${LUADIR}/src/libluajit.a generated
	${LUADIR}/src/luajit -b $< $@

${BUILDDIR}/webserver: src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	mkdir -p ${BUILDDIR}
	$(CC) -Wall -o ${BUILDDIR}/webserver src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o \
	  -I${HTTPDIR} -I${UVDIR}/include -lrt -lm

${BUILDDIR}/luvit: src/luvit.c src/utils.c src/luv.c src/lhttp_parser.c ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o generated/http.c generated/tcp.c generated/utils.c generated/luvit.c
	mkdir -p ${BUILDDIR}
	$(CC) -Wall -g -o ${BUILDDIR}/luvit src/luvit.c src/utils.c src/luv.c src/lhttp_parser.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${LUADIR}/src/libluajit.a generated/http.c generated/tcp.c generated/utils.c generated/luvit.c \
	  -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -lm -ldl -lrt

clean:
	make -C ${LUADIR} clean
	make -C ${HTTPDIR} clean
	make -C ${UVDIR} distclean
	rm -rf build generated




