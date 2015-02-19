APP_FILES=$(shell find . -type f -name '*.lua')
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)

luvit: lit $(APP_FILES)
	./lit make

test: luvit
	./luvit tests/run.lua

clean:
	rm -rf luvit lit luvi

lit:
	curl -L https://github.com/luvit/lit/raw/0.9.3/web-install.sh | sh

install: luvit
	install luvit /usr/local/bin

uninstall:
	rm -f /usr/local/bin/luvit

lint:
	find app -name "*.lua" | xargs luacheck
