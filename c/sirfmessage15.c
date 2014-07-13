/* $CSK: sirfmessage15.c,v 1.6 2006/09/21 04:35:09 ckuethe Exp $ */

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
#include "sirfmessage15.h"

struct sm15 *
sirf_decode_message_15(xbuf *packet){
	unsigned char *b;
	struct sm15 *r;

	if ((r = malloc(sizeof(struct sm15))) == NULL)
		return NULL;
	bzero(r, sizeof(struct sm15));

	b = packet->buf; /* alias */

	r->prn = b[5];

	r->sf1.how.prn = b[ 7];
	r->sf1.how.subframe =  (b[11]>>2) &0x07 ;
	r->sf1.how.antispoof = (b[11]>>5) &0x01 ;
	r->sf1.how.alert =     (b[11]>>6) &0x01 ;
	r->sf1.how.tow =       (((b[9]&0xff)<<9) | ((b[10]&0xff)<<1) |
				((b[11]>>7)&0x01)) &0x0001ffff ;

	r->sf1.dat.ura =       (b[13] &0x0f);
	r->sf1.dat.tgd =       (b[26] &0xff);
	r->sf1.dat.af2 =       (b[30] &0xff);
	r->sf1.dat.l2_codes =  (b[13]>>4) &0x03;
	r->sf1.dat.health =    (b[14]>>2) &0x3f;
	r->sf1.dat.l2_no_nav = (b[15]>>7) &0x01;
	r->sf1.dat.week =      (b[12]<<2)+((b[13]>>6) &0x03);
	r->sf1.dat.toc =       (b[28]<<8)+(b[29] &0xff);
	r->sf1.dat.iodc =      ((b[14] &0x03)<<8) + (b[27] &0xff);
	r->sf1.dat.af1 |=      ((b[31] &0xff)<<8) | (b[32]&0xff);
	r->sf1.dat.af0 =       (((b[33]&0xff)<<24) | ((b[34]&0xff)<<16) |
				((b[35]&0xff)<<8)) / 1024;


	r->sf2.how.prn = b[37];
	r->sf2.how.subframe =  (b[41]>>2) &0x07 ;
	r->sf2.how.antispoof = (b[41]>>5) &0x01 ;
	r->sf2.how.alert =     (b[41]>>6) &0x01 ;
	r->sf2.how.tow =       (((b[39]&0xff)<<9) | ((b[40]&0xff)<<1) |
				((b[41]>>7)&0x01)) &0x0001ffff ;
	r->sf2.dat.iode =      (b[42] &0xff);
	r->sf2.dat.aodo =      (b[63]>> 2) &0x1f;
	r->sf2.dat.f =         (b[63]>> 7) &0x01;
	r->sf2.dat.c_rs =      (b[43]<< 8) | (b[44] &0xff);
	r->sf2.dat.delta_n =   (b[45]<< 8) | (b[46] &0xff);
	r->sf2.dat.c_uc =      (b[51]<< 8) | (b[52] &0xff);
	r->sf2.dat.c_us =      (b[57]<< 8) | (b[58] &0xff);
	r->sf2.dat.t_oe =      (b[63]<< 8) | (b[64] &0xff);
	r->sf2.dat.m0 |=       ((b[47]&0xff)<<24) | ((b[48]&0xff)<<16) |
				((b[49]&0xff)<<8) | (b[50]&0xff);
	r->sf2.dat.e |=        ((b[53]&0xff)<<24) | ((b[54]&0xff)<<16) |
				((b[55]&0xff)<<8) | (b[56]&0xff);
	r->sf2.dat.sqrtA |=    ((b[59]&0xff)<<24) | ((b[60]&0xff)<<16) |
				((b[61]&0xff)<<8) | (b[62]&0xff);

	r->sf3.how.prn = b[67];
	r->sf3.how.subframe =  (b[71]>>2) &0x07 ;
	r->sf3.how.antispoof = (b[71]>>5) &0x01 ;
	r->sf3.how.alert =     (b[71]>>6) &0x01 ;
	r->sf3.how.tow =       (((b[69]&0xff)<<9) | ((b[70]&0xff)<<1) |
				((b[71]>>7)&0x01)) &0x0001ffff ;
	r->sf3.dat.iode =      (b[93] &0xff);
	r->sf3.dat.c_ic =      (b[72]<< 8) | (b[73] &0xff);
	r->sf3.dat.c_is =      (b[78]<< 8) | (b[79] &0xff);
	r->sf3.dat.c_rc =      (b[84]<< 8) | (b[85] &0xff);
	r->sf3.dat.i_dot =     (b[94]<< 6) | ((b[95]>>2) &0xff);
	r->sf3.dat.omega0 |=   ((b[74]&0xff)<<24) | ((b[75]&0xff)<<16) |
				((b[76]&0xff)<<8) | (b[77]&0xff);
	r->sf3.dat.i0 |=       ((b[80]&0xff)<<24) | ((b[81]&0xff)<<16) |
				((b[82]&0xff)<<8) | (b[83]&0xff);
	r->sf3.dat.w |=        ((b[86]&0xff)<<24) | ((b[87]&0xff)<<16) |
				((b[88]&0xff)<<8) | (b[89]&0xff);
	r->sf3.dat.omega_dot = (((b[90]&0xff)<<24) | ((b[91]&0xff)<<16) |
				((b[92]&0xff)<<8)) / 256;

	return r; 
}

void
dump_message_15(struct sm15 *m){
	float u[] = {2.4, 3.4, 4.85, 6.85, 9.65, 13.65, 24.0, 48.0, 96.0,
	    192.0, 384.0, 768.0, 1536.0, 3072.0, 6144.0, -1.0};

	if (!(m->prn && m->sf1.how.prn && m->sf2.how.prn && m->sf3.how.prn))
		return;

	printf("prn: %u", m->prn);
	printf("\nsubframe 1 (clock correction):\n");
	printf("handover word:\n");
	printf("\tprn: %u subframe: %u\n", m->sf1.how.prn,
		m->sf1.how.subframe);
	printf("\ttow: %u\n", m->sf1.how.tow);
	printf("\talert: %u antispoof: %u\n", m->sf1.how.alert,
		m->sf1.how.antispoof);
	printf("data:\n");
	printf("\tweek: %u\n", m->sf1.dat.week);
	printf("\tL2 Codes: %u\n", m->sf1.dat.l2_codes);
	printf("\tL2pc (L2 not modulated with NAV): %u\n",
		m->sf1.dat.l2_no_nav);
	printf("\thealth: %02x\n", m->sf1.dat.health);
	if (m->sf1.dat.ura > 15)
		printf("\tURA: invalid (0x%02x)\n", m->sf1.dat.ura);
	else if (m->sf1.dat.ura == 15)
		printf("\tURA: no prediction (0x%02x)\n", m->sf1.dat.ura);
	else
		printf("\tURA: %u (<%0.2fm)\n", m->sf1.dat.ura,
		    u[m->sf1.dat.ura]);
	printf("\tIODC: %hu\n", m->sf1.dat.iodc);
	printf("\tGroup Differential (Tgd): %d\n", m->sf1.dat.tgd);
	printf("\tClock Data Reference Time (TOC): %hu\n", m->sf1.dat.toc);
	printf("\tClock Correction (af2): %d\n", m->sf1.dat.af2);
	printf("\tClock Correction (af1): %hd\n", m->sf1.dat.af1);
	printf("\tClock Correction (af0): %d\n", m->sf1.dat.af0);

	printf("\nsubframe 2 (ephemeris):\n");
	printf("handover word:\n");
	printf("\tprn: %u, subframe: %u\n", m->sf2.how.prn,
		m->sf2.how.subframe);
	printf("\ttow: %u\n", m->sf2.how.tow);
	printf("\talert: %u, antispoof: %u\n", m->sf2.how.alert,
		m->sf2.how.antispoof);
	printf("data:\n");
	printf("\tIODE: %u\n", m->sf2.dat.iode);
	printf("\tTime of Ephemeris (Toe): %d\n", m->sf2.dat.t_oe);
	printf("\tFit Interval >4hrs (f): %u\n", m->sf2.dat.f);
	printf("\tAge of Data Offset (aodo): %u\n", m->sf2.dat.aodo);
	printf("\tOrbit Radius Sine Harmonic (Crs): %hd\n", m->sf2.dat.c_rs);
	printf("\tLatitude Cosine Harmonic (Cuc): %hd\n", m->sf2.dat.c_uc);
	printf("\tLatitude Sine Harmonic (Cus): %hd\n", m->sf2.dat.c_us);
	printf("\tMean Motion Difference (delta_n): %hd\n",
		m->sf2.dat.delta_n);
	printf("\tMean Anomaly (M0): %d\n", m->sf2.dat.m0);
	printf("\tOrbital Eccentricity (e): %d\n", m->sf2.dat.e);
	printf("\tsqrt(semi-major axis) (sqrtA): %d\n", m->sf2.dat.sqrtA);

	printf("\nsubframe 3 (ephemeris):\n");
	printf("handover word:\n");
	printf("\tprn: %u, subframe: %u\n", m->sf3.how.prn,
		m->sf3.how.subframe);
	printf("\ttow: %u\n", m->sf3.how.tow);
	printf("\talert: %u, antispoof: %u\n", m->sf3.how.alert,
		m->sf3.how.antispoof);
	printf("data:\n");
	printf("\tIODE: %u\n", m->sf3.dat.iode);
	printf("\tInclination Cosine Harmonic (Cic): %hd\n", m->sf3.dat.c_ic);
	printf("\tInclination Sine Harmonic (Cis): %hd\n", m->sf3.dat.c_is);
	printf("\tOrbit Radius Cosine Harmonic (Crc): %hd\n", m->sf3.dat.c_rc);
	printf("\tPerigee (w): %d\n", m->sf3.dat.w);
	printf("\tAscendNode Orbital Plane (omega0): %d\n", m->sf3.dat.omega0);
	printf("\tRight Ascension Rate (omegadot): %d\n",
		m->sf3.dat.omega_dot);
	printf("\tInclination Angle (i0): %d\n", m->sf3.dat.i0);
	printf("\tInclination Angle Rate (idot): %hd\n", m->sf3.dat.i_dot);
}
