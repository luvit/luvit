APP_FILES=$(shell find app -type f)

luvit: $(APP_FILES)
	lit make app

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
