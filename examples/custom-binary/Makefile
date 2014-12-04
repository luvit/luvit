combined: ../../luvit  $(shell find extras -type f)
	LUVI_TARGET=combined LUVI_APP=extras: luvit

../../luvit:
	$(MAKE) -C ../..

clean:
	rm -f combined
