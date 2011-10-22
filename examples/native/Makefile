LUADIR=../../deps/luajit

# On my machine (Ubuntu 11.10) I needed the following libraries:
# libgtk-3-dev libwebkitgtk-3.0-dev

all: topcube.luvit

%.o: %.c %.h
	$(CC) -Wall -Werror -fPIC -c $< -o $@ -I${LUADIR}/src `pkg-config --cflags glib-2.0 gtk+-3.0 webkitgtk-3.0`

topcube.luvit: topcube.o
	$(CC) -shared -o topcube.luvit topcube.o `pkg-config --libs glib-2.0 gtk+-3.0 webkitgtk-3.0`

clean:
	rm topcube.o topcube.luvit
