/* $CSK: sirfmessage14.h,v 1.1 2006/09/17 02:01:06 ckuethe Exp $ */

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

#ifndef __SIRFMESSAGE14_H__
#define __SIRFMESSAGE14_H__

/*
 * since these structures contain the information in the almanac message, but
 * in a different size or byte order, elements are sorted in the structure:
 * largest to smallest, then unsigned first, and then alphabetically. Element
 * sizes are all powers of two. Structures are padded to 32-bit lengths
 */

struct sm14 {
	u_int32_t	sqrtA;
	int32_t		m0, omega0, w;
	u_int16_t	cksum1, cksum2, e, week;
	int16_t		af0, af1, omega_dot, sigma_i;
	u_int8_t	data_id, health, prn, status, svid, t_oa;

	u_int8_t	junk[2];
};

struct sm14 * sirf_decode_message_14(xbuf *); /* ephemeris */
void dump_message_14(struct sm14 *);
#endif /* __SIRFMESSAGE14_H__ */
