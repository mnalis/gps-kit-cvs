/* $CSK: sirfutils.c,v 1.15 2006/09/18 00:02:04 ckuethe Exp $ */

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

extern char *malloc_options;
xbuf *
xballoc(size_t len){
	xbuf *xb = malloc(sizeof(xbuf));
	if (xb){
		xb->max = len;
		xb->len = 0;
		xb->buf = malloc(len);
		if (xb->buf)
			return xb;
		free(xb);
	}
	return NULL;
}

void
xbfree(xbuf *xb){
	xb->max = xb->len = 0;
	free(xb->buf);
	free(xb);
}

int
sirf_open(char *port, int speed) {
	struct termios	config;	
	int		fd;

	fd = open(port, O_RDWR|O_NOCTTY|O_NONBLOCK, O_NDELAY);

	if (fd == -1) {
		err(1,"open"); /* XXX */
	}

	fcntl(fd, F_SETFL, 0);

	tcgetattr(fd, &config);

	cfsetispeed(&config, speed);
	cfsetospeed(&config, speed);
	config.c_cflag |= (CLOCAL | CREAD);
	config.c_cflag &= ~PARENB;
	config.c_cflag &= ~CSTOPB;
	config.c_cflag &= ~CSIZE;
	config.c_cflag |= CS8;
	config.c_iflag &= ~(IXON | IXOFF | IXANY);
	config.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
	config.c_oflag &= ~OPOST;

	tcsetattr(fd, TCSANOW, &config);

	return fd;
}

int
sirf_setspeed(int fd, int speed) {
	struct termios	config;	
	int r;

	/* the SiRF gps will only run at these speeds */
	if ((speed != 4800) && (speed != 9600) && (speed != 14400) && 
	    (speed != 28800) && (speed != 38400) && (speed != 57600))
		return -1;

/*	log_debug("setting SiRF reference to %d bps", speed); */

	tcgetattr(fd, &config);
	cfsetispeed(&config, speed);
	cfsetospeed(&config, speed);
	r = tcsetattr(fd, TCSADRAIN, &config);
	usleep(1000);
	return r;
}

int
sirf_setproto(int fd, int proto, int speed) {
	/*
	 * $PSRF100,1,38400,8,1,0*3D<cr><lf> = 27 bytes
	 * SiRF binary message to set speed and protocol = 53 bytes
	 * 64 is a nice round number.
	 */
	int r = 0;
	struct uartconfig uart;
	struct portconfig p0 = {0x00,0,0,38400,8,1,0};
	struct portconfig p1 = {0xff,5,5,    0,0,0,0};
	struct portconfig p2 = {0xff,5,5,    0,0,0,0};
	struct portconfig p3 = {0xff,5,5,    0,0,0,0};
	xbuf *mesg = xballoc(64);

/*	log_debug("setting SiRF reference to protocol %d", proto); */

	/* build the appropriate set proto/speed NMEA message */
	snprintf("PSRF100,%d,%d,8,1,0", mesg->max -1, (char *)mesg->buf, proto, speed);
	snprintf("$%s*%02X\r\n", mesg->max -1, (char *)mesg->buf, mesg->buf, nmea_checksum(mesg->buf));

	/*
	 * Spam the GPS with a command to set binary mode at 38400bps
	 * One of these will work if the receiver is in NMEA mode.
	 * strlen() works because NMEA strings are null terminated.
	 */
	r += sirf_setspeed(fd,  4800); write(fd, mesg->buf, strlen((char *)mesg->buf));
	r += sirf_setspeed(fd,  9600); write(fd, mesg->buf, strlen((char *)mesg->buf));
	r += sirf_setspeed(fd, 14400); write(fd, mesg->buf, strlen((char *)mesg->buf));
	r += sirf_setspeed(fd, 28800); write(fd, mesg->buf, strlen((char *)mesg->buf));
	r += sirf_setspeed(fd, 38400); write(fd, mesg->buf, strlen((char *)mesg->buf));
	r += sirf_setspeed(fd, 57600); write(fd, mesg->buf, strlen((char *)mesg->buf));

	/*
	 * Build the appropriate set proto/speed SiRF message. Consumer GPS
	 * modules are likely to have only one port (like mine does). I don't
	 * think that any multiport receivers (which would be found in eval
	 * kits would have their alternate ports affected by this.
	 */

	bzero(mesg->buf, mesg->max);
	mesg->buf[0] = 0xa5; mesg->len++;
	bcopy(&p0, (mesg->buf)+ 1, 12); mesg->len += 12;
	bcopy(&p1, (mesg->buf)+13, 12); mesg->len += 12;
	bcopy(&p2, (mesg->buf)+25, 12); mesg->len += 12;
	bcopy(&p3, (mesg->buf)+37, 12); mesg->len += 12;

	bzero(&uart, sizeof(uart));
	uart.hdr = 0xa0a2;
	uart.len = 49;
	bcopy(mesg->buf,&uart.hdr, mesg->len);
	uart.cksum = sirf_checksum(mesg);
	uart.trailer = 0xb0b3;
	/*
	 * Spam the GPS with a command to set binary mode at 38400bps
	 * One of these will work if the receiver is in NMEA mode.
	 */
	sirf_setspeed(fd,  4800); write(fd, &uart, 57); usleep(1000);
	sirf_setspeed(fd,  9600); write(fd, &uart, 57); usleep(1000);
	sirf_setspeed(fd, 14400); write(fd, &uart, 57); usleep(1000);
	sirf_setspeed(fd, 28800); write(fd, &uart, 57); usleep(1000);
	sirf_setspeed(fd, 38400); write(fd, &uart, 57); usleep(1000);
	sirf_setspeed(fd, 57600); write(fd, &uart, 57); usleep(1000);
	xbfree(mesg);

	return (sirf_setspeed(fd, speed)); /* leave the gps at the desired speed */
}


unsigned char
sirf_type(xbuf *packet){
	unsigned char c = 0;
	c = packet->buf[4];
	return c;
}

int
sirf_is_valid(xbuf *packet){
	u_int16_t chk, junk;
	xbuf *body;

	bcopy(&packet->buf[0], &junk, 2);
	junk = ntohs(junk);
	if (junk != 0xa0a2)
		return 0;

	bcopy(&packet->buf[(packet->len)-2], &junk, 2);
	junk = ntohs(junk);
	if (junk != 0xb0b3)
		return 0;

	bcopy(&packet->buf[2], &junk, 2);
	junk = ntohs(junk);

	body = xballoc(junk);
	bcopy((packet->buf)+4,body->buf,body->max);
	body->len = body->max;

	chk = htons(sirf_checksum(body));
	bcopy(&packet->buf[(packet->len)-4], &junk, 2);
	xbfree(body);

	if (chk != junk)
		return 0;

	return 1;
}

u_int16_t
sirf_checksum(xbuf *packet){
	u_int16_t c = 0;
	int i;

	for(i = 0; i < packet->len; i++) {
		c += (unsigned char)packet->buf[i];
	}
	c = c & 0x7fff;
	return c;
}

u_int8_t
nmea_checksum(u_int8_t *buf){
	unsigned char c = 0;

	while (*buf != '\0') {
		c ^= *buf;
		buf++;
	}

	return c;
}

struct timeval
sirf_gps2unix(int week, double tow, int leap){
	struct timeval tv;
	/*
	 * magic numbers:
	 * 	GPS time started at unix second 315964800
	 *	there are 604800 seconds in a week (7 * 60 * 60 * 24)
	 */

	tv.tv_sec = (315964800 + (week * 604800) + tow - leap);
	tv.tv_usec = (tow - (int)tow) * 1000000;
	return tv;
}

struct sm_2 *
sirf_decode_message_2(xbuf *packet){
	struct sm_2 str, *r;
	u_int32_t n4;
	u_int16_t n2;
	u_int8_t n1;
	
	bzero(&str,sizeof(str));
	xbdump(packet);

	bcopy(&packet->buf[0], &n2, 2);
	str.hdr = ntohs(n2);

	bcopy(&packet->buf[2], &n2, 2);
	str.len = ntohs(n2);

	bcopy(&packet->buf[4], &n1, 1);
	str.mid = n1;

	bcopy(&packet->buf[5], &n4, 4);
	str.xpos = ntohl(n4);

	bcopy(&packet->buf[9], &n4, 4);
	str.ypos = ntohl(n4);

	bcopy(&packet->buf[13], &n4, 4);
	str.zpos = ntohl(n4);

	bcopy(&packet->buf[17], &n2, 2);
	str.xvel = ntohs(n2)/8.0;

	bcopy(&packet->buf[19], &n2, 2);
	str.yvel = ntohs(n2)/8.0;

	bcopy(&packet->buf[21], &n2, 2);
	str.zvel = ntohs(n2)/8.0;

	bcopy(&packet->buf[5], &n1, 1);
	str.mid = n1;

	bcopy(&packet->buf[22], &n1, 1);
	str.mode1 = n1 & 0xff;

	bcopy(&packet->buf[23], &n1, 1);
	str.dop = n1/5;

	bcopy(&packet->buf[24], &n1, 1);
	str.mode2 = n1 & 0xff;

	bcopy(&packet->buf[26], &n2, 2);
	str.week = ntohs(n2);

	bcopy(&packet->buf[28], &n4, 4);
	str.week = ntohl(n4)/100.0;

	bcopy(&packet->buf[32], &n1, 1);
	str.ch1 = n1;

	bcopy(&packet->buf[33], &n1, 1);
	str.ch2 = n1;

	bcopy(&packet->buf[34], &n1, 1);
	str.ch3 = n1;

	bcopy(&packet->buf[35], &n1, 1);
	str.ch4 = n1;

	bcopy(&packet->buf[36], &n1, 1);
	str.ch5 = n1;

	bcopy(&packet->buf[37], &n1, 1);
	str.ch6 = n1;

	bcopy(&packet->buf[38], &n1, 1);
	str.ch7 = n1;

	bcopy(&packet->buf[39], &n1, 1);
	str.ch8 = n1;

	bcopy(&packet->buf[40], &n1, 1);
	str.ch9 = n1;

	bcopy(&packet->buf[41], &n1, 1);
	str.ch10 = n1;

	bcopy(&packet->buf[42], &n1, 1);
	str.ch11 = n1;

	bcopy(&packet->buf[43], &n1, 1);
	str.ch12 = n1;

	bcopy(&packet->buf[44], &n2, 2);
	str.cksum = ntohs(n2);
	bcopy(&packet->buf[46], &n2, 2);
	str.trailer = ntohs(n2);

	r = malloc(packet->len);
	bcopy(&str,r,packet->len);
	return r; 
}

struct sm_41 *
sirf_decode_message_41(xbuf *packet){
	struct sm_41 *r;

	r = malloc(packet->len);
	bzero(r, packet->len);
	bcopy(packet->buf, r, packet->len);
	r->utc_year = ntohs(r->utc_year);
	r->utc_sec = ntohs(r->utc_sec);
	r->week = ntohs(r->week);
	r->speed = ntohs(r->speed);
	r->course = ntohs(r->course);

	r->tow = ntohl(r->tow);
	r->lat = ntohl(r->lat);
	r->lon = ntohl(r->lon);
	r->alt_e = ntohl(r->alt_e);
	r->alt_m = ntohl(r->alt_m);
	return r; 
}

struct sm_7 *
sirf_decode_message_7(xbuf *packet){
	struct sm_7 str, *r;
	u_int32_t n4;
	u_int16_t n2;
	u_int8_t n1;
	
	bzero(&str,sizeof(str));

	bcopy(&packet->buf[0], &n2, 2);
	str.hdr = ntohs(n2);

	bcopy(&packet->buf[2], &n2, 2);
	str.len = ntohs(n2);

	bcopy(&packet->buf[4], &n1, 1);
	str.mid = n1;

	bcopy(&packet->buf[11], &n1, 1);
	str.svs = n1;

	bcopy(&packet->buf[5], &n2, 2);
	str.week = ntohs(n2);

	bcopy(&packet->buf[7], &n4, 4);
	str.tow = ntohl(n4);

	bcopy(&packet->buf[12], &n4, 4);
	str.drift = ntohl(n4);

	bcopy(&packet->buf[16], &n4, 4);
	str.bias = ntohl(n4);

	bcopy(&packet->buf[20], &n4, 4);
	str.gpstime = ntohl(n4);

	bcopy(&packet->buf[24], &n2, 2);
	str.cksum = ntohs(n2);

	bcopy(&packet->buf[26], &n2, 2);
	str.trailer = ntohs(n2);

	r = malloc(packet->len);
	bcopy(&str,r,packet->len);
	return r; 
}

struct sm_30 *
sirf_decode_message_30(xbuf *packet){
	struct sm_30 str, *r;
	u_int64_t n8;
	u_int32_t n4;
	u_int16_t n2;
	u_int8_t n1;
	int i = 0;
	
	bzero(&str,sizeof(str));

	bcopy(&packet->buf[i], &n2, 2);
	str.hdr = ntohs(n2); i += 2;

	bcopy(&packet->buf[i], &n2, 2);
	str.len = ntohs(n2); i += 2;

	bcopy(&packet->buf[i], &n1, 1);
	str.mid = n1; i += 1;

	bcopy(&packet->buf[i], &n1, 1);
	str.svid = n1; i += 1;

	bcopy(&packet->buf[i], &n8, 8);
	str.xpos = sirftohd(n8); i += 8;

	bcopy(&packet->buf[i], &n8, 8);
	str.ypos = sirftohd(n8); i += 8;

	bcopy(&packet->buf[i], &n8, 8);
	str.zpos = sirftohd(n8); i += 8;

	bcopy(&packet->buf[i], &n8, 8);
	str.xvel = sirftohd(n8); i += 8;

	bcopy(&packet->buf[i], &n8, 8);
	str.yvel = sirftohd(n8); i += 8;

	bcopy(&packet->buf[i], &n8, 8);
	str.zvel = sirftohd(n8); i += 8;

	bcopy(&packet->buf[i], &n8, 8);
	str.bias = sirftohd(n8); i += 8;

	bcopy(&packet->buf[i], &n8, 4);
	str.drift = sirftohf(n4); i += 4;

	bcopy(&packet->buf[i], &n1, 1);
	str.ephemeris = n1; i += 1;

	bcopy(&packet->buf[i], &n4, 4);
	str.pad0 = ntohs(n4); i += 4;

	bcopy(&packet->buf[i], &n4, 4);
	str.pad1 = ntohs(n4); i += 4;

	bcopy(&packet->buf[i], &n4, 4);
	str.delay = sirftohd(n4); i += 4;

	bcopy(&packet->buf[i], &n2, 2);
	str.cksum = ntohs(n2);

	bcopy(&packet->buf[i], &n2, 2);
	str.trailer = ntohs(n2);

	r = malloc(packet->len);
	bcopy(&str,r,packet->len);
	return r; 
}

u_int8_t *
sirf_decode_message_255(xbuf *packet){
	u_int8_t *str;
	if((str = malloc(packet->len)) != NULL){
		snprintf((char *)str, packet->len-7, "%s", (packet->buf)+5);
		return str; 
	}
	return NULL;
}

void
xbdump(xbuf *xb){
	size_t i;
	printf(" xbdump: \t");
	for(i = 0; i < xb->len; i++)
		printf("%02x ", (unsigned char)(xb->buf[i]));

	printf("\n");
}


void
hexdump(u_int8_t * buf, size_t len){
	size_t i, j;

	i = 0;
	j = len;
	while (j >= 4){
		if (i % 4 == 0){
			if (i % 16 == 0)
				printf("\n%08x: ", (unsigned int)i);
			else
				printf("  ");
		}
		printf("%02x %02x %02x %02x ",
		    (unsigned char)(buf[i]),
		    (unsigned char)(buf[i+1]),
		    (unsigned char)(buf[i+2]),
		    (unsigned char)(buf[i+3]));
		i+=4;
		j -= 4;

	}

	if (i % 4 == 0){
		if (i % 16 == 0)
			printf("\n%08x: ", (unsigned int)i);
		else
			printf("  ");
	}

	switch (j){
	case 3:
		printf("%02x ", (unsigned char)(buf[i]));
		i++;
	case 2:
		printf("%02x ", (unsigned char)(buf[i]));
		i++;
	case 1:
		printf("%02x ", (unsigned char)(buf[i]));
	default:
		break;
	}
	printf("\n\n");
}

float
sirftohf(u_int32_t i){
	float f;
	i = ntohl(i);
	bcopy(&i,&f,4);
	return f;
}

double
sirftohd(u_int64_t i){
	double d;
	u_int32_t a, b;

	bcopy(&i,&a,4);
	bcopy(&i+4,&b,4);
	a = ntohl(a);
	b = ntohl(b);

#if BYTE_ORDER == LITTLE_ENDIAN
	/* l3 l2 l1 l0.h3 h2 h1 h0 -> l0 l1 l2 l3.h0 h1 h2 h3 */
	bcopy(&a,&d,4);
	bcopy(&b,&d+4,4);
#else
	/* l3 l2 l1 l0.h3 h2 h1 h0 -> h3 h2 h1 h0.l3 l2 l1 l0 */
	bcopy(&a,&d+4,4);
	bcopy(&b,&d,4);
#endif
	return d;
}
