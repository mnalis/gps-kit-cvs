/* $CSK: sirfutils.h,v 1.13 2006/09/07 15:19:16 ckuethe Exp $ */

/*
 * Copyright (c) 2004-2006 Chris Kuethe <ckuethe@ualberta.ca>
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

/*
 * This is a driver for gps receivers based on the SiRFstarIIe/LP chipset,
 * and the Rayming TripNav TN-200 in porticular. One of the nice features
 * of the SiRF is that one well-documented packet gives you GPS time down
 * to the microsecond. Unfortunately that must be balanced against the fact
 * that it's nigh-impossible to get UTC time out of the GPS without the use
 * of very nasty tricks (falling back to NMEA to steal UTC from there or
 * doing all sorts of ugly things to an ugly format implemented in an uglier
 * fashion.
 * 
 * RTFM:
 * 	http://www.rayming.com/download/SiRF%20Binary%20Protocol.pdf
 * 	http://www.arinc.com/gps/icd200c.pdf
 * 
 */

typedef struct {
	size_t	len, max;
	u_int8_t *buf;
} xbuf;

struct portconfig {
	u_int8_t	port;
	u_int8_t	p_in;
	u_int8_t	p_out;
	u_int32_t	baud;
	u_int8_t	data;
	u_int8_t	stop;
	u_int8_t	par;
	u_int16_t	pad;
}  __attribute__ ((__packed__));

struct uartconfig {
	u_int16_t	hdr;
	u_int16_t	len;
	u_int16_t	cksum;
	u_int16_t	trailer;
}  __attribute__ ((__packed__));

struct sm_2 {
	u_int16_t	hdr;
	u_int16_t	len;

	u_int32_t	tow;
	int32_t		xpos, ypos, zpos;
	u_int16_t	week;
	int16_t		xvel, yvel, zvel;

	u_int8_t	mid;
	u_int8_t	mode1, dop, mode2;
	u_int8_t	ch1, ch2, ch3, ch4, ch5, ch6;
	u_int8_t	ch7, ch8, ch9, ch10, ch11, ch12;
	u_int8_t	svs;

	u_int16_t	cksum;
	u_int16_t	trailer;
}  __attribute__ ((__packed__));

struct sm_7 {
	u_int16_t	hdr;
	u_int16_t	len;
	
	u_int32_t	tow;
	u_int32_t	drift;
	u_int32_t	bias;
	u_int32_t	gpstime;

	u_int16_t	week;

	u_int8_t	mid;
	u_int8_t	svs;

	u_int16_t	cksum;
	u_int16_t	trailer;
}  __attribute__ ((__packed__));

struct sm_8{
	u_int16_t	hdr;
	u_int16_t	len;
	
	u_int32_t	tlm;
	u_int32_t	how;

	u_int32_t	w2, w3, w4, w5, w6, w7, w8, w9;

	u_int16_t	cksum;
	u_int16_t	trailer;
}  __attribute__ ((__packed__));

struct sm_30{
	u_int16_t	hdr;
	u_int16_t	len;

	double		gpstime;
	double		xpos, ypos, zpos;
	double		xvel, yvel, zvel;
	double		bias;

	float		drift;
	float		delay;

	u_int8_t	mid;
	u_int8_t	svid;
	u_int8_t	ephemeris;

	u_int8_t	pad;
	u_int32_t	pad0;
	u_int32_t	pad1;

	u_int16_t	cksum;
	u_int16_t	trailer;
}  __attribute__ ((__packed__));

struct sm_41{
	u_int16_t	hdr;
	u_int16_t	len;

	u_int16_t	valid, type, week;
	u_int32_t	tow;

	u_int16_t	utc_year;
	u_int8_t	utc_mon, utc_day, utc_hr, utc_min;
	u_int16_t	utc_sec;

	u_int32_t	svlist;

	u_int32_t	lat, lon;
	u_int32_t	alt_e, alt_m;

	u_int8_t	datum;
	u_int16_t	speed, course, magvar;
	u_int16_t	climb_rate, course_rate;

	u_int32_t	ehpe, evpe, ete, ehve;
	u_int32_t	clkbias, e_clkbias;
	u_int32_t	clkdrift, e_clkdrift;
	u_int32_t	distance;
	u_int16_t	distance_e, course_e;

	u_int8_t	svs, hdop, modeinfo;

	u_int16_t	cksum;
	u_int16_t	trailer;
}  __attribute__ ((__packed__));

#define sirf_close(x) do { sirf_setproto((x),1,4800) ; close((x)); } while (0)


int		sirf_open(char *, int);
int		sirf_setspeed(int, int);
int		sirf_setproto(int, int, int);
struct timeval	sirf_gps2unix(int, double, int);
xbuf *		xballoc(size_t);
u_int8_t	nmea_checksum(u_int8_t *);
int		sirf_is_valid(xbuf *);
u_int16_t	sirf_checksum(xbuf *);
u_int8_t	sirf_type(xbuf *);
float		sirftohf(u_int32_t);
double		sirftohd(u_int64_t);
void		xbfree(xbuf *);
void		xbdump(xbuf *);
void		hexdump(u_int8_t *, size_t);

struct sm_2 * sirf_decode_message_2(xbuf *); /* navigaton data */
struct sm_7 * sirf_decode_message_7(xbuf *); /* clock status */
struct sm_41 * sirf_decode_message_41(xbuf *); /* geodetic navigation data */
struct sm_30 * sirf_decode_message_30(xbuf *); /* navlib SV state */
u_int8_t * sirf_decode_message_255(xbuf *); /* debug */
