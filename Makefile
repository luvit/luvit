APP_FILES=$(shell find app -type f)
LUVI_BIN=luvi-binaries/$(shell uname -s)_$(shell uname -m)/luvi

luvit: $(LUVI_BIN) $(APP_FILES)
	LUVI_APP=app LUVI_TARGET=luvit $(LUVI_BIN)

$(LUVI_BIN):
	git submodule update --init

test: luvit
	./luvit tests/run.lua

clean:
	rm -f luvit

install: luvit
	install luvit /usr/local/bin

uninstall:
	rm -f /usr/local/bin/luvit

lint:
	find app -name "*.lua" | xargs luacheck
