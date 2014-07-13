/* $CSK: select.c,v 1.13 2006/09/21 04:38:10 ckuethe Exp $ */

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

#include <sys/types.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <mysql.h>

#include "sirfutils.h"
#include "sirfmessage14.h"
#include "sirfmessage15.h"

extern char * malloc_options;

int
main(){
	char *sql;
	u_int8_t *str;
	char *dbname, *dbhost, *dbuser, *dbpass;
	xbuf *packet;
	unsigned long *length;

	MYSQL *my_conn;
	MYSQL_RES *my_res;
	MYSQL_ROW my_row;

	malloc_options = "AFGJXZ";
	dbname = "gpsobservatory";
	dbhost = "127.0.0.1";
	dbuser = "gpsobserver";
	dbpass = "gpsobserver";

	/* magic times from a 30 minute observation, 13/08/2004 1537h */
	sql = "SELECT SQL_CACHE msgtime,msg FROM observations WHERE ((session_id = 52) AND (msgtype = 41)) ORDER BY msgtime LIMIT 8";
/*	sql = "SELECT msgtime,msg FROM observations WHERE ((msgtime > 1092433036) AND (msgtime < 1092434857) AND (msgtype = 7)) ORDER BY msgtime LIMIT 2"; */
/*	sql = "SELECT msgtime,msg FROM observations WHERE (msgtype = 255) ORDER BY msgtime"; */

	my_conn = (MYSQL *)malloc(sizeof(MYSQL));
	mysql_init(my_conn);
	if(mysql_real_connect(my_conn, dbhost, dbuser, dbpass, dbname, 0, 0, 0) == 0){
		if(mysql_errno(my_conn)) {
			printf("database: mysql_error: %s\n", mysql_error(my_conn));
			exit(1);
		}
		printf("database: Failed to logon to database '%s'\n", dbname);
		exit(1);
	}

	if((my_res = (MYSQL_RES *)mysql_query(my_conn,sql))) {
		if(mysql_errno(my_conn))
			printf("database: mysql_error: %s\nSQL=%s\n", mysql_error(my_conn), sql);
	} else {
		my_res = mysql_store_result(my_conn);
		printf("selected %d rows\n", (int)mysql_num_rows(my_res));
		while ((my_row = mysql_fetch_row(my_res))){
			length = mysql_fetch_lengths(my_res);
			if((packet = xballoc(length[1])) != NULL){

			bcopy(my_row[1],packet->buf,packet->max);
			packet->len = packet->max;

			printf("==============================================================\n");
			printf("%s  \ttype %d, len %d (%svalid)\n", my_row[0],
				sirf_type(packet), packet->len,
				sirf_is_valid(packet)?"":"in" );

			switch (sirf_type(packet)){
#if 0
			case 2:
				str = (u_int8_t *)sirf_decode_message_2(packet);
				printf("Position: %d %d %d\nVelocity: %f %f %f\nMode: %02x %02x DOP %f\nWeek: %d\tTOW: %f\nSVs: %d\nCh1: %d Ch2: %d Ch3: %d Ch4: %d\nCh5: %d Ch6: %d Ch7: %d Ch8: %d\nCh9: %d Ch10: %d Ch11: %d Ch12: %d\n",
				((struct sm_2 *)str)->xpos, ((struct sm_2 *)str)->ypos,
				((struct sm_2 *)str)->zpos, ((struct sm_2 *)str)->xvel,
				((struct sm_2 *)str)->yvel, ((struct sm_2 *)str)->zvel,

				((struct sm_2 *)str)->mode1, ((struct sm_2 *)str)->mode2,
				((struct sm_2 *)str)->dop, ((struct sm_2 *)str)->week,
				((struct sm_2 *)str)->tow, ((struct sm_2 *)str)->svs,

				((struct sm_2 *)str)->ch1, ((struct sm_2 *)str)->ch2,
				((struct sm_2 *)str)->ch3, ((struct sm_2 *)str)->ch4,
				((struct sm_2 *)str)->ch5, ((struct sm_2 *)str)->ch6,
				((struct sm_2 *)str)->ch7, ((struct sm_2 *)str)->ch8,
				((struct sm_2 *)str)->ch9, ((struct sm_2 *)str)->ch10,
				((struct sm_2 *)str)->ch11, ((struct sm_2 *)str)->ch2);

				free(str);
				break;
#endif
#if 0
			case 7:
				str = (u_int8_t *)sirf_decode_message_7(packet);
				printf("week: %d\ntow: %f\nSVs: %d\ndrift: %d\nbias: %d\ngpstime: %f\n",
				((struct sm_7 *)str)->week,
				((struct sm_7 *)str)->tow / 100.0,
				((struct sm_7 *)str)->svs,
				((struct sm_7 *)str)->drift,
				((struct sm_7 *)str)->bias,
				((struct sm_7 *)str)->gpstime/ 1000.0);
				free(str);
				break;
#endif
			case 14:
				str = (u_int8_t *)sirf_decode_message_14(packet);
				dump_message_14((struct sm14 *)str);
				free(str);
				break;
			case 15:
				str = (u_int8_t *)sirf_decode_message_15(packet);
				dump_message_15((struct sm15 *)str);
				free(str);
				break;
			case 41:
				hexdump(packet->buf, packet->len);
				str = (u_int8_t *)sirf_decode_message_41(packet);
				printf("solution %s\n", ((struct sm_41 *)str)->valid ? "OK" : "BAD");
				printf("UTC: %4d-%02d-%02d %02d:%02d:%06.3f\n",
				((struct sm_41 *)str)->utc_year,
				((struct sm_41 *)str)->utc_mon,
				((struct sm_41 *)str)->utc_day,
				((struct sm_41 *)str)->utc_hr,
				((struct sm_41 *)str)->utc_min,
				((struct sm_41 *)str)->utc_sec/1000.0);

				printf("week: %d\ttow: %.3f\nlat: %f\nlon: %f\nalt: %.2f\n",
				((struct sm_41 *)str)->week,
				((struct sm_41 *)str)->tow / 1000.0,
				((struct sm_41 *)str)->lat / 1e7,
				((struct sm_41 *)str)->lon / 1e7,
				((struct sm_41 *)str)->alt_e / 100.0);
				free(str);
				break;
#if 0
			case 30:
				str = (u_int8_t *)sirf_decode_message_30(packet);
				printf("week: %d\ntow: %f\nSVs: %d\ndrift: %d\nbias: %d\ngpstime: %f\n",
				((struct sm_30 *)str)->svid,
				((struct sm_30 *)str)->gpstime,
				((struct sm_30 *)str)->ephemeris,

				((struct sm_30 *)str)->xpos,
				((struct sm_30 *)str)->ypos,
				((struct sm_30 *)str)->zpos,
				((struct sm_30 *)str)->xvel,
				((struct sm_30 *)str)->yvel,
				((struct sm_30 *)str)->zvel,

				((struct sm_30 *)str)->drift,
				((struct sm_30 *)str)->bias,
				((struct sm_30 *)str)->delay,
				((struct sm_30 *)str)->gpstime/ 1000.0);
				free(str);
				break;
#endif
			case 255:
				str = (u_int8_t *)sirf_decode_message_255(packet);
				printf("%s\n", str);
				free(str);
				break;
			default:
				break;
			}

			xbfree(packet);
			}
		}
	}
	mysql_close(my_conn);
	return 0;
}
