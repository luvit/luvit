CFLAGS=$(shell luvit --cflags)
LIBS=$(shell luvit --libs)

all: vector.luvit

%.o: %.c %.h
	$(CC) -c $< -o $@ ${CFLAGS}

vector.luvit: vector.o
	$(CC) -o vector.luvit vector.o ${LIBS}

clean:
	rm -f vector.o vector.luvit
