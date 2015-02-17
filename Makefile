APP_FILES=$(shell find app -type f)
LIT_FILES=$(shell find lit/app -type f)
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)

luvit: lit/lit $(LIT_FILES) $(APP_FILES)
	#lit/lit make app
	LUVI_APP=app LUVI_TARGET=luvit $(BIN_ROOT)/luvi

lit/Makefile:
	git submodule update --init --recursive

lit/lit: lit/Makefile $(LIT_FILES)
	make -C lit

test: luvit
	LUVI_APP=app ./luvit tests/run.lua
	./luvit tests/run.lua

clean:
	rm -rf luvit

install: luvit
	install luvit /usr/local/bin

uninstall:
	rm -f /usr/local/bin/luvit

lint:
	find app -name "*.lua" | xargs luacheck
