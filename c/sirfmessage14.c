/* $CSK: sirfmessage14.c,v 1.2 2006/09/17 05:19:13 ckuethe Exp $ */

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
#include "sirfmessage14.h"

struct sm14 *
sirf_decode_message_14(xbuf *packet){
	char *b;
	struct sm14 *r;

	if ((r = malloc(sizeof(struct sm14))) == NULL)
		return NULL;
	bzero(r, sizeof(struct sm14));

	b = packet->buf; /* alias */

	r->prn =	b[5] &0xff;
	r->week =	(b[6]<<2) + ((b[7]>>6) &0x03);
	r->status =	(b[7] &0x3f);
	r->data_id=	(b[8]>>6) &0x03;
	r->svid=	(b[8] &0x3f);
	r->e =		(b[9]<<8)+(b[10] &0xff);
	r->t_oa =	b[11] &0xff;
	r->sigma_i =	((b[12] &0xff)<<8) | (b[13]&0xff);
	r->omega_dot =	((b[14] &0xff)<<8) | (b[15]&0xff);
	r->health =	b[16] &0xff;
	r->sqrtA =	((b[17] &0xff)<<16) | ((b[18] &0xff)<<8) | (b[19]&0xff);
	r->omega0 =	((b[20] &0xff)<<16) | ((b[21] &0xff)<<8) | (b[22]&0xff);
	r->w =		((b[23] &0xff)<<16) | ((b[24] &0xff)<<8) | (b[25]&0xff);
	r->m0 =		((b[26] &0xff)<<16) | ((b[27] &0xff)<<8) | (b[28]&0xff);
	r->af0 =	(((b[29] &0xff)<<16) | ((b[31] &0x1c)<<11))/32;
	r->af1 =	(((b[30] &0xff)<<16) | ((b[31] &0xe0)<<8))/32;
	r->cksum1 =	((b[32] &0xff)<<8) | (b[33]&0xff);

	return r; 
}

void
dump_message_14(struct sm14 *m){
	if (0 == m->data_id)
		return;

	printf("prn: %u\n\t", m->prn);
	printf("week: %u\n\t", m->week);
	printf("status: %02x\n\t", m->status);
	printf("data id: %02x\n\t", m->data_id);
	printf("svid: %u\n\t", m->prn);
	printf("Orbital Eccentricity (e): %d\n\t", m->e);
	printf("Time of Almanac (Toa): %d\n\t", m->t_oa);
	printf("Inclination Angle Deviation (sigma_i): %d\n\t", m->sigma_i);
	printf("Right Ascension Rate (omegadot): %d\n\t", m->omega_dot);
	printf("health: %02x\n\t", m->health);
	printf("sqrt(semi-major axis) (sqrtA): %d\n\t", m->sqrtA);
	printf("AscendNode Orbital Plane (omega0): %d\n\t", m->omega0);
	printf("Perigee (w): %d\n\t", m->w);
	printf("Mean Anomaly (M0): %d\n\t", m->m0);
	printf("Clock Correction (af0): %d\n\t", m->af0);
	printf("Clock Correction (af1): %hd\n", m->af1);
	return;
}
