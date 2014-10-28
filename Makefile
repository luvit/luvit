LUVI_BIN=$(shell which luvi)
APP_FILES=$(shell find app -type f)

luvit: $(LUVI_BIN) app.zip
	cat $^ > $@
	chmod +x $@

app.zip: $(APP_FILES)
	cd app && zip ../app.zip -r -9 . ; cd -

test: luvit
	# LUVI_DIR=app luvi tests/test-colors.lua
	./luvit tests/run.lua

clean:
	rm luvit app.zip
