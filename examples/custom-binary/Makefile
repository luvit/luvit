APP_FILES=$(shell find . -type f -name "*.lua")
custom-binary: $(APP_FILES)
	lit make .

test: custom-binary
	./custom-binary 1 2 3

clean:
	rm -f custom-binary
