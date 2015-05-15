APP_FILES=$(shell find . -type f -name '*.lua')
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)
LIT_VERSION=1.2.8

LUVIT_TAG=$(shell git describe)
LUVIT_ARCH=$(shell uname -s)_$(shell uname -m)

luvit: lit $(APP_FILES)
	./lit make

test: luvit
	./luvit tests/run.lua

clean:
	rm -rf luvit lit lit-* luvi luvit.tar.gz

lit:
	curl -L https://github.com/luvit/lit/raw/$(LIT_VERSION)/get-lit.sh | sh

install: luvit lit
	install luvit /usr/local/bin
	install lit /usr/local/bin
	install luvi /usr/local/bin

uninstall:
	rm -f /usr/local/bin/luvit
	rm -f /usr/local/bin/lit

lint:
	find deps -name "*.lua" | xargs luacheck

luvit.tar.gz: luvit lit README.markdown ChangeLog LICENSE.txt
	echo 'Copy `lit` and `luvit` to somewhere in your path like /usr/local/bin/' > INSTALL
	tar -czf luvit.tar.gz INSTALL README.markdown ChangeLog LICENSE.txt luvit lit
	rm INSTALL

publish: luvit.tar.gz
	github-release upload --user luvit --repo luvit --tag ${LUVIT_TAG} \
	  --file luvit.tar.gz --name luvit-${LUVI_ARCH}.tar.gz
