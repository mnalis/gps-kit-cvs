/* $CSK: sirfmessage8.h,v 1.2 2006/09/21 04:36:22 ckuethe Exp $ */

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

#ifndef __SIRFMESSAGE8_H__
#define __SIRFMESSAGE8_H__

struct sm8 {
	u_int32_t	words[10];
	u_int32_t	tow;
	u_int8_t	channel, prn;
	u_int8_t	alert, antispoof, subframe, page, leap;
	char		text[23];
	u_int8_t	junk[2];
};

struct sm8 * sirf_decode_message_8(xbuf *); /* ephemeris */
void dump_message_8(struct sm8 *);
void bindump(char *, u_int32_t);
#endif /* __SIRFMESSAGE14_H__ */
