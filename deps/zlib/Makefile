ZLIBS=contrib/minizip/ioapi.o   \
      contrib/minizip/unzip.o   \
      contrib/minizip/zip.o     \
      adler32.o  \
      compress.o \
      crc32.o    \
      deflate.o  \
      gzio.o     \
      infback.o  \
      inffast.o  \
      inflate.o  \
      inftrees.o \
      trees.o    \
      uncompr.o  \
      zutil.o

libz.a: ${ZLIBS}
	$(AR) rvs libz.a ${ZLIBS}

%.o: %.c
	$(CC) -c $< -o $@

clean:
	rm -f *.o *.a
