APP_FILES=$(shell find app -type f)

luvit: lit $(APP_FILES)
	./lit make app

luvi-binaries:
	git clone --depth 1 https://github.com/luvit/luvi-binaries.git

lit-app:
	git clone --depth 1 https://github.com/luvit/lit.git lit-app

lit: luvi-binaries lit-app
	LUVI_APP=lit-app/app LUVI_TARGET=$@ luvi-binaries/$(shell uname -s)_$(shell uname -m)/luvi


test: luvit
	./luvit tests/run.lua

clean:
	rm -rf luvit lit lit-app luvi-binaries

install: luvit
	install luvit /usr/local/bin

uninstall:
	rm -f /usr/local/bin/luvit

lint:
	find app -name "*.lua" | xargs luacheck
