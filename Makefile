APP_FILES=$(shell find app -type f)
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)

luvit: lit $(APP_FILES)
	./lit make app

lit:
	curl https://gist.githubusercontent.com/creationix/439dd5c985734c9cee59/raw/faface25202d3a76e6d6e2f9c7d66ed7f4212d7c/web-install.sh | sh

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
