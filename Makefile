APP_FILES=$(shell find app -type f)
LIT_FILES=$(shell find lit/app -type f)

luvit: lit/lit $(LIT_FILES) $(APP_FILES)
	lit/lit make app

lit/Makefile:
	git submodule init
	git submodule update --depth 1


lit/lit: lit/Makefile $(LIT_FILES)
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
