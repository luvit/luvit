APP_FILES=$(shell find . -type f -name '*.lua')
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)

luvit: lit $(APP_FILES)
	./lit make

test: luvit
	./luvit tests/run.lua

clean:
	rm -rf luvit lit lit-* luvi

lit:
	curl -L https://github.com/luvit/lit/raw/0.9.9/get-lit.sh | sh

install: luvit lit
	install luvit /usr/local/bin
	install lit /usr/local/bin

uninstall:
	rm -f /usr/local/bin/luvit
	rm -f /usr/local/bin/lit

lint:
	find modules -name "*.lua" | xargs luacheck
