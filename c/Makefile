# $CSK: Makefile,v 1.7 2006/09/21 04:38:10 ckuethe Exp $
LDFLAGS= -g -L/usr/local/lib -lmysqlclient
CPPFLAGS= -I/usr/local/include/mysql -I.
CFLAGS= -g -Wall -pedantic -Wno-long-long
CC= gcc $(CFLAGS)

OBJS= sirfproto.o select.o sirfutils.o sirfmessage14.o sirfmessage15.o
all: $(OBJS) sirfproto select

sirfproto: sirfproto.o
	$(CC) -pipe -O2 -o sirfproto sirfproto.o

select: select.o sirfutils.o sirfmessage14.o sirfmessage15.o
	$(CC) -o select $(LDFLAGS) select.o sirfutils.o sirfmessage14.o sirfmessage15.o

clean:
	@rm -f sirfproto select *.o *core
