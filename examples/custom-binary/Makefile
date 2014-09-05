all: combined

extras.zip:
	cd extras && zip -9 -r ../extras.zip . && cd ..

combined: ../../out/Debug/luvit extras.zip
	cat $^ > $@ && chmod +x $@

clean:
	rm -f combined extras.zip

