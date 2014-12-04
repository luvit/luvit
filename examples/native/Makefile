CFLAGS=-fPIC -I/home/tim/Code/luvi/deps/luv/luajit/src
LIBS=-shared

all: vector.so

%.o: %.c %.h
	$(CC) -c $< -o $@ ${CFLAGS}

vector.so: vector.o
	$(CC) -o $@ $< ${LIBS}

clean:
	rm -f vector.o vector.luvit vector.so
