LUADIR=deps/LuaJIT-2.0.0-beta8

all: luanode

lua:
	$(MAKE) -C ${LUADIR}

luanode: lua luanode.c
	${CC} -o luanode luanode.c -I${LUADIR}/src -L${LUADIR}/src -lluajit -lm -ldl

distclean: clean clean-lua

clean:
	rm -f repl

clean-lua:
	make -C deps/LuaJIT-2.0.0-beta8 clean



