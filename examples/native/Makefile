LUADIR=../../deps/luajit

all: vector.luvit

%.o: %.c %.h
	$(CC) -Wall -Werror -fPIC -c $< -o $@ -I${LUADIR}/src

vector.luvit: vector.o
	$(CC) -shared -o vector.luvit vector.o -lm

clean:
	rm vector.o vector.luvit
