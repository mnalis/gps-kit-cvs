/* $CSK: sirfmessage15.h,v 1.1 2006/09/17 00:02:31 ckuethe Exp $ */

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

#ifndef __SIRFMESSAGE15_H__
#define __SIRFMESSAGE15_H__

/*
 * since these structures contain the information in the almanac message, but
 * in a different size or byte order, elements are sorted in the structure:
 * largest to smallest, then unsigned first, and then alphabetically. Element
 * sizes are all powers of two. Structures are padded to 32-bit lengths
 */

struct _sm15_how {
	u_int32_t	tow;
	u_int8_t	alert, antispoof, prn, subframe;
};

struct _sm15_sf1data{
	int32_t		af0;
	u_int16_t	af1, iodc, toc, week;
	u_int8_t	health, l2_codes, l2_no_nav, ura;
	int8_t		tgd, af2;

	u_int8_t junk[2];
};

struct _sm15_sf2data{
	u_int32_t	sqrtA;
	int32_t		e, m0;
	int16_t		c_rs, c_uc, c_us, delta_n, t_oe;
	u_int8_t	aodo, f, iode;

	u_int8_t junk[3];
};

struct _sm15_sf3data{
	int32_t		i0, omega_dot, omega0, w;
	int16_t		c_ic, c_is, c_rc, i_dot;
	u_int8_t	iode;

	u_int8_t junk[3];
};

struct _sm15_sf1 {
	struct _sm15_how how;
	struct _sm15_sf1data dat;
};

struct _sm15_sf2 {
	struct _sm15_how how;
	struct _sm15_sf2data dat;
};

struct _sm15_sf3 {
	struct _sm15_how how;
	struct _sm15_sf3data dat;
};

struct sm15 {
	struct _sm15_sf1	sf1;
	struct _sm15_sf2	sf2;
	struct _sm15_sf3	sf3;
	u_int8_t	prn;

	u_int8_t junk[3];
};

struct sm15 * sirf_decode_message_15(xbuf *); /* ephemeris */
void dump_message_15(struct sm15 *);
#endif /* __SIRFMESSAGE15_H__ */
