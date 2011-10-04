LUADIR=deps/luajit
UVDIR=deps/uv
HTTPDIR=deps/http-parser
BUILDDIR=build
GENDIR=${BUILDDIR}/generated

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

${GENDIR}:
	mkdir -p ${GENDIR}

${GENDIR}/%.c: lib/%.lua ${LUADIR}/src/libluajit.a ${GENDIR}
	${LUADIR}/src/luajit -b $< $@

${GENDIR}/%.o: ${GENDIR}/%.c
	$(CC) -c $< -o $@

${BUILDDIR}/webserver: ${BUILDDIR} src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	mkdir -p ${BUILDDIR}
	$(CC) -Wall -o ${BUILDDIR}/webserver src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o \
	  -I${HTTPDIR} -I${UVDIR}/include -lrt -lm

${BUILDDIR}/luvit: ${BUILDDIR} src/luvit.c src/utils.c src/luv.c src/lhttp_parser.c ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${GENDIR}/http.o ${GENDIR}/tcp.o ${GENDIR}/luvit.o ${GENDIR}/utils.o
	$(CC) -Wall -o ${BUILDDIR}/luvit src/luvit.c src/utils.c src/luv.c src/lhttp_parser.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${LUADIR}/src/libluajit.a ${GENDIR}/http.o ${GENDIR}/tcp.o ${GENDIR}/luvit.o ${GENDIR}/utils.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -lm -ldl -lrt -Wl,-E

clean:
	make -C ${LUADIR} clean
	make -C ${HTTPDIR} clean
	make -C ${UVDIR} distclean
	rm -rf build




