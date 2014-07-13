# $CSK: Makefile,v 1.3 2004/08/14 22:37:35 ckuethe Exp $
.PATH:	${.CURDIR}/..
LIBS= -L/usr/local/lib -lmysqlclient -lc -lssl -lcrypto
LDFLAGS= -g -pg -O2
CPPFLAGS= -I/usr/local/include/mysql -I. -I.. -I..
CFLAGS= -g -pg -O2
CC= gcc $(CFLAGS)

DECODERS=	sirfmessage15.o sirfmessage14.o sirfmessage8.o
UTILS=		sirfutils.o gpsd_report.o isgps.o
PROGOBJS=	select.o select8.o select14.o select15.o
PROGS=		select8 select14 select15 select test8

all: $(DECODERS) $(UTILS) $(PROGOBJS) $(PROGS)

select: $(DECODERS) $(UTILS) select.o
	$(CC) -o select $(LDFLAGS) $(LIBS) $(DECODERS) $(UTILS) select.o

select8: $(DECODERS) $(UTILS) select8.o
	$(CC) -o select8 $(LDFLAGS) $(LIBS) $(DECODERS) $(UTILS) select8.o

select14: $(DECODERS) $(UTILS) select14.o
	$(CC) -o select14 $(LDFLAGS) $(LIBS) $(DECODERS) $(UTILS) select14.o

select15: $(DECODERS) $(UTILS) select15.o
	$(CC) -o select15 $(LDFLAGS) $(LIBS) $(DECODERS) $(UTILS) select15.o

test8: $(DECODERS) $(UTILS) test8.o
	$(CC) -o test8 $(LDFLAGS) $(LIBS) $(DECODERS) $(UTILS) test8.o

test15: $(DECODERS) $(UTILS) test15.o
	$(CC) -o test15 $(LDFLAGS) $(LIBS) $(DECODERS) $(UTILS) test15.o

clean:
	@rm -f select select8 select14 select15 test15 *.o *core gmon.out
