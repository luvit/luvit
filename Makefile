LUADIR=deps/LuaJIT-2.0.0-beta8

all: repl

lua:
	$(MAKE) -C ${LUADIR}

repl: lua repl.c
	${CC} -o repl repl.c -I${LUADIR}/src -L${LUADIR}/src -lluajit -lm -ldl
clean-lua:
	make -C deps/LuaJIT-2.0.0-beta8 clean

dist-clean: clean clean-lua

clean:
	rm -f *.o
	rm -f repl



