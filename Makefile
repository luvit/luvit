APP_FILES=$(shell find . -type f -name '*.lua')
BIN_ROOT=lit/luvi-binaries/$(shell uname -s)_$(shell uname -m)
LIT_VERSION=3.5.4

LUVIT_TAG=$(shell git describe)
LUVIT_ARCH=$(shell uname -s)_$(shell uname -m)

PREFIX?=/usr/local
PHONY?=test lint size trim lit

test: lit luvit
	./luvi . -- tests/run.lua

clean:
	git clean -dx -f


lit:
	curl -L https://github.com/luvit/lit/raw/$(LIT_VERSION)/get-lit.sh | sh

luvit: lit $(APP_FILES)
	./lit make

install: luvit lit
	mkdir -p $(PREFIX)/bin
	install luvit $(PREFIX)/bin/
	install lit $(PREFIX)/bin/
	install luvi $(PREFIX)/bin/

uninstall:
	rm -f $(PREFIX)/bin/luvit
	rm -f $(PREFIX)/bin/lit


tools/certdata.txt:
	curl https://hg.mozilla.org/mozilla-central/raw-file/tip/security/nss/lib/ckfw/builtins/certdata.txt -o tools/certdata.txt

tools/certs.pem: tools/certdata.txt tools/convert_mozilla_certdata.go
	cd tools && go run convert_mozilla_certdata.go > certs.pem

tools/certs.dat: tools/certs.pem tools/convert.lua
	luvit tools/convert

update-certs:	tools/certs.dat
	cp tools/certs.dat deps/tls/root_ca.dat


lint:
	find deps -name "*.lua" | xargs luacheck

size:
	find deps -type f -name '*.lua' | xargs  -I{} sh -c "luajit -bs {} - | echo \`wc -c\` {}" | sort -n

trim:
	find . -type f -name '*.lua' -print0 | xargs -0 perl -pi -e 's/ +$$//'

luvit.tar.gz: luvit lit README.markdown ChangeLog LICENSE.txt
	echo 'Copy `lit` and `luvit` to somewhere in your path like /usr/local/bin/' > INSTALL
	tar -czf luvit.tar.gz INSTALL README.markdown ChangeLog LICENSE.txt luvit lit
	rm INSTALL

publish: luvit.tar.gz
	github-release upload --user luvit --repo luvit --tag ${LUVIT_TAG} \
	  --file luvit.tar.gz --name luvit-${LUVI_ARCH}.tar.gz
