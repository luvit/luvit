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
	$(MAKE) -C ${UVDIR} uv.a

${HTTPDIR}/http_parser.o:
	make -C ${HTTPDIR} http_parser.o

${BUILDDIR}:
	ln -sf ${LUADIR}/lib jit
	mkdir -p ${BUILDDIR}

src/generated:
	mkdir -p src/generated

src/generated/%.h: lib/%.lua ${LUADIR}/src/libluajit.a src/generated
	${LUADIR}/src/luajit -bg $< $@

${BUILDDIR}/webserver: ${BUILDDIR} src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	mkdir -p ${BUILDDIR}
	$(CC) -Wall -o ${BUILDDIR}/webserver src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o \
	  -I${HTTPDIR} -I${UVDIR}/include -lrt -lm


${BUILDDIR}/luvit: ${BUILDDIR} src/luvit.c src/utils.c src/luv.c src/lhttp_parser.c ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o src/generated/http.h src/generated/tcp.h src/generated/utils.h src/generated/luvit.h
	$(CC) -Wall -g -o ${BUILDDIR}/luvit src/luvit.c src/utils.c src/luv.c src/lhttp_parser.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${LUADIR}/src/libluajit.a -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -lm -ldl -lrt -Wl,-E

clean:
	make -C ${LUADIR} clean
	make -C ${HTTPDIR} clean
	make -C ${UVDIR} distclean
	rm -rf build src/generated




