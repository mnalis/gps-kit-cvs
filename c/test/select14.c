/* $CSK: select.c,v 1.9 2005/06/10 18:11:03 ckuethe Exp $ */

/*
 * Copyright (c) 2004,2005 Chris Kuethe <ckuethe@ualberta.ca>
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

extern char * malloc_options;

int
main(){
	char *sql;
	u_int8_t *str;
	struct sm14 *r;
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

	sql = "SELECT SQL_CACHE msgtime,msg FROM observations WHERE (session_id=52 AND msgtype=14) ORDER BY obs_id";

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

			hexdump(packet->buf, packet->len);
			switch (sirf_type(packet)){
			case 14:
				r = sirf_decode_message_14(packet);
				dump_message_14(r);
				free(r);
				/* FALLTHROUGH */
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
