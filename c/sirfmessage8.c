/* $CSK: sirfmessage8.c,v 1.3 2006/09/21 04:25:41 ckuethe Exp $ */

/*
 * Copyright (c) 2006 Chris Kuethe <ckuethe@ualberta.ca>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>

#include <string.h>
#include <strings.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <err.h>
#include <time.h>

#include "sirfutils.h"
#include "sirfmessage8.h"

#define GETWORD(y, x) do {(y) = ((b[(x)] &0xff)<<24) | \
			((b[(x)+1] &0xff)<<16) | \
			((b[(x)+2] &0xff)<< 8) | \
			(b[(x)+3] &0xff); \
			(y) = ((y) & 0x3fffffff) >>6; } while (0)


struct sm8 *
sirf_decode_message_8(xbuf *packet){
	int i;
	char *b;
	struct sm8 *r;

	if ((r = malloc(sizeof(struct sm8))) == NULL)
		return NULL;
	bzero(r, sizeof(struct sm8));

	b = packet->buf; /* alias */

	r->channel =	b[5] &0xff;
	r->prn =	b[6] &0xff;

	for (i = 0 ; i < 10; i++)
		GETWORD(r->words[i],  4*i+7) ;

	if ((r->words[0] &0x00ff0000) == 0x740000)
		for (i = 0 ; i < 10; i++)
			r->words[i] ^= 0x00ffffff;


	r->subframe = (r->words[0]>>2) &0x07 ;
	r->antispoof = (r->words[0]>>5) &0x01 ;
	r->alert = (r->words[0]>>6) &0x01 ;
	r->tow = (r->words[0]>>7) &0x01ffff ;
	/* ICD, p.105 - dataid, svid and page mappings */
	r->page = (r->words[2] & 0x3F0000) >> 16;

	/* ICD, p.76, 115 4/17 - Special Messages*/
	if ((r->subframe == 4) && (r->page == 55)){
		bzero(r->text, 23);
		r->text[ 0] = (r->words[2]>> 8)&0xff;
		r->text[ 1] = (r->words[2]    )&0xff;
		r->text[ 2] = (r->words[3]>>16)&0xff;
		r->text[ 3] = (r->words[3]>> 8)&0xff;
		r->text[ 4] = (r->words[3]    )&0xff;
		r->text[ 5] = (r->words[4]>>16)&0xff;
		r->text[ 6] = (r->words[4]>> 8)&0xff;
		r->text[ 7] = (r->words[4]    )&0xff;
		r->text[ 8] = (r->words[5]>>16)&0xff;
		r->text[ 9] = (r->words[5]>> 8)&0xff;
		r->text[10] = (r->words[5]    )&0xff;
		r->text[11] = (r->words[6]>>16)&0xff;
		r->text[12] = (r->words[6]>> 8)&0xff;
		r->text[13] = (r->words[6]    )&0xff;
		r->text[14] = (r->words[7]>>16)&0xff;
		r->text[15] = (r->words[7]>> 8)&0xff;
		r->text[16] = (r->words[7]    )&0xff;
		r->text[17] = (r->words[8]>>16)&0xff;
		r->text[18] = (r->words[8]>> 8)&0xff;
		r->text[19] = (r->words[8]    )&0xff;
		r->text[20] = (r->words[9]>>16)&0xff;
		r->text[21] = (r->words[9]>> 8)&0xff;
	}

	/* ICD, p.76, 4/18 - GPS-UTC Leap Seconds*/
	if ((r->subframe == 4) && (r->page == 56)){
		r->leap = (r->words[8] & 0xff0000) >> 16;
		if (r->leap > 128)
			r->leap ^= 0xff;
	}

	/* ICD, p.76, 4/25*/
	/* ICD, p.73, 5/25*/
	if ((r->subframe == 5) && (r->page == 51)){ ; }
	return r; 
}

void
dump_message_8(struct sm8 *m){
	int i;
	char c[37];
	printf("prn: %u\n", m->prn);
	printf("channel: %u\n", m->channel);
	printf("subframe: %u\n", m->subframe);
	printf("page: %u\n", m->page);
	printf("leap: %u\n", m->leap);
	printf("tow: %u\n", m->tow);
	printf("antispoof: %u\n", m->antispoof);
	printf("alert: %u\n", m->alert);
	
	for (i = 0 ; i < 10; i++){
		bindump(c, m->words[i]);
		printf("word %2d: %08x %36s\n", i+1, m->words[i], c);
	}

	return;
}

void
bindump(char * buf, u_int32_t x){
	int i, j;

	memset(buf, ' ', 37);
	for(i = 0; i<32; i++){
		j = i/8;
		if (x &(1<<i))
			buf[36-i-j] = '1';
		else
			buf[36-i-j] = '0';
	}

	buf[37] = '\0';
	return;
}
