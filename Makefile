APP_FILES=$(shell find app -type f)
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)

luvit: lit/lit $(APP_FILES)
	lit/lit make app

lit/Makefile:
	git submodule update --init --recursive

lit/lit: lit/Makefile
	make -C lit

test: luvit
	./luvit tests/run.lua

clean:
	rm -rf luvit

install: luvit
	install luvit /usr/local/bin

uninstall:
	rm -f /usr/local/bin/luvit

lint:
	find app -name "*.lua" | xargs luacheck
