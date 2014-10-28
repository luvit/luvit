APP_FILES=$(shell find app -type f)
LUVI_BIN=luvi-binaries/$(shell uname -s)_$(shell uname -m)/luvi

all: luvit

$(LUVI_BIN):
	git submodule update --init

app.zip: $(APP_FILES)
	cd app && zip ../app.zip -r -9 . ; cd -

luvit: $(LUVI_BIN) app.zip
	cat $^ > $@
	chmod +x $@

test: luvit
	# LUVI_DIR=app luvi tests/test-colors.lua
	./luvit tests/run.lua

clean:
	rm luvit app.zip
