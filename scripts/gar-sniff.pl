#!/usr/bin/perl

# $CSK: gar-sniff.pl,v 1.5 2006/09/07 15:17:36 ckuethe Exp $

# Copyright (c) 2004-2006 Chris Kuethe <ckuethe@ualberta.ca>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

BEGIN {
    unshift (@INC, "/home/ckuethe/cvs/local/gps/p5-gps");
}

use Device::SerialPort;
use GPS::Tools;
use GPS::Garmin::Decoders;
use GPS::Garmin::Lib;
use Time::HiRes		qw(gettimeofday usleep time);
use Time::Local;

use warnings;
use strict;

# http://playground.sun.com/pub/soley/garmin.txt
# http://www.abnormal.com/~thogard/gps/grmnprot.html
# http://www.garmin.com/support/commProtocol.html
# http://artico.lma.fi.upm.es/numerico/miembros/antonio/async/
# http://www.jensar.us/~bob/garmin/

$SIG{'INT'} = $SIG{'HUP'} = $SIG{'TERM'} = \&bye;
my ($DEV, $sp, $rl, $msg, $b, $v, $packet, $type, $typedecode, @pq, %pctl);

%pctl = (	22 => 1);
$sp=init_serial("/dev/gps", 9600);

while(1){	# dle, type, len, body, cksum, dle, etx (*2 for escape bytes)
	do {
		($rl, $b) = $sp->read(6);
		$msg = $b;
		usleep(10000);
	} until ($rl > 5);

	do {
		($rl, $b) = $sp->read(4);
		$msg .= $b;
	} until ($msg =~ /(\x10.+\x10\x03)/);

	$msg = unescape($msg);
	packet_parse($msg);
}
