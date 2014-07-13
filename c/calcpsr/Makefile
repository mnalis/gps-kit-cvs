# $CSK: Makefile,v 1.7 2006/09/15 15:42:30 ckuethe Exp $
CC=cc
CFLAGS=-pipe -O2 -Wall -g -I.
CPPFLAGS=-Wall -ansi
LDFLAGS=

OBJS= calcpsr.o caleph.o main.o
.c.o: datstruc.h defines.h protos.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(DFLAGS) -c $< -o $*.o

all: calcpsr

calcpsr: $(OBJS)
	cc $(CFLAGS) $(LDFLAGS) -o calcpsr $(OBJS)

reallyclean: clean cleandata

cleandata:
	rm -f *.core p_range.* svdata.* *.msr *.eph

clean:
	rm -f $(OBJS) *.core calcpsr
