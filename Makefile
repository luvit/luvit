LUADIR=deps/luajit
UVDIR=deps/uv
HTTPDIR=deps/http-parser
BUILDDIR=build
GENDIR=${BUILDDIR}/generated

all: luvit

${GENDIR}:
	mkdir -p ${GENDIR}

webserver: ${BUILDDIR}/webserver

luvit: ${BUILDDIR}/luvit

${LUADIR}/src/libluajit.a:
	$(MAKE) -C ${LUADIR}

${UVDIR}/uv.a:
	$(MAKE) -C ${UVDIR} uv.a

${HTTPDIR}/http_parser.o:
	make -C ${HTTPDIR} http_parser.o

${GENDIR}/%.c: lib/%.lua ${LUADIR}/src/libluajit.a
	${LUADIR}/src/luajit -b $< $@

${GENDIR}/%.o: ${GENDIR}/%.c
	$(CC) -Wall -c $< -o $@

${BUILDDIR}/webserver: src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o
	$(CC) -Wall -o ${BUILDDIR}/webserver src/webserver.c ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o -I${HTTPDIR} -I${UVDIR}/include -lrt -lm

${BUILDDIR}/%.o: src/%.c
	mkdir -p ${BUILDDIR}
	$(CC) -Wall -c $< -o $@ -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

${BUILDDIR}/luvit: ${GENDIR} ${BUILDDIR}/luvit.o ${BUILDDIR}/utils.o ${BUILDDIR}/luv.o ${BUILDDIR}/lhttp_parser.o ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${GENDIR}/http.o ${GENDIR}/tcp.o ${GENDIR}/luvit.o ${GENDIR}/utils.o
	$(CC) -o ${BUILDDIR}/luvit ${BUILDDIR}/luvit.o ${BUILDDIR}/utils.o ${BUILDDIR}/luv.o ${BUILDDIR}/lhttp_parser.o ${LUADIR}/src/libluajit.a ${UVDIR}/uv.a ${HTTPDIR}/http_parser.o ${GENDIR}/http.o ${GENDIR}/tcp.o ${GENDIR}/luvit.o ${GENDIR}/utils.o -Wall -lm -ldl -lrt -Wl,-E

clean:
	make -C ${LUADIR} clean
	make -C ${HTTPDIR} clean
	make -C ${UVDIR} distclean
	rm -rf build

install: ${BUILDDIR}/luvit
	install ${BUILDDIR}/luvit -s -v /usr/local/bin/luvit

