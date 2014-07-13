#!/usr/bin/perl

# $CSK: nmea-time.pl,v 1.5 2006/09/07 15:17:36 ckuethe Exp $

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

use warnings;
use strict;

use Device::SerialPort;
use Time::HiRes qw( gettimeofday usleep );
use Time::Local;

# http://search.cpan.org/src/SREZIC/perl-GPS-0.14/NMEA/Handler.pm
# http://www.gpsinformation.org/dale/nmea.htm
# http://www.commlinx.com.au/NMEA_sentences.htm
# http://pcptpp030.psychologie.uni-regensburg.de/trafficresearch/NMEA0183/
# http://vancouver-webpages.com/peter/idx_nmeadoc.html



$SIG{'INT'} = $SIG{'HUP'} = $SIG{'TERM'} = \&bye;
my ($PORT, $sp, $s, $v, %m, %old);
my ($tm, @tm);

$PORT = "/dev/cuaU0";
$sp = Device::SerialPort->new ($PORT) || die "Can't Open $PORT: $!";
$sp->baudrate(4800)	|| die "failed setting baudrate";
$sp->parity("none")	|| die "failed setting parity";
$sp->databits(8)	|| die "failed setting databits";
$sp->handshake("none")	|| die "failed setting handshake";

open(DEV, "<$PORT") || die "Cannot open $PORT: $!\n";

$| = 1;
while(<DEV>){
	$tm = sprintf("%02d%02d%02d", (gmtime())[2,1,0]);
	next unless (/^\$(\w{5}),(.+)$/);
	($s,$v) = ($1, $2);


	$@ = "";

	eval {my $func = \&{"parse_$s"} ; &$func($v); } ;
	print "Unhandled record type: $s\n" if ($@);

	finish_record() if (($s eq "GPRTE") && ($v =~ /^(\d+),\1,/));
}


sub bye{
	#do cleanup stuff here
	close DEV;
	undef $sp;
	die "Caught signal... exiting.\n"
}

###########################################################################
#   * GPGGA
#   * GPRMC
#   * GPZDA

#   * GPGSA
#   * GPGSV

sub parse_PGRME{ return ; }
sub parse_PGRMZ{ return ; }
sub parse_GPRTE{ return ; }
sub parse_GPBOD{ return ; }
sub parse_GPRMB{ return ; }
sub parse_GPGSV{ return ; }

sub parse_GPGGA{ 
	(
	$m{'fixdata.time'},
	undef) = split(/[,\*]/ , $_[0]);
	$m{'fixdata.gtod'} = $tm;
}

sub parse_GPRMC{ 
	(
	$m{'pvt.time'},
	$m{'pvt.status'},
	undef,
	undef,
	undef,
	undef,
	undef,
	undef,
	$m{'pvt.date'},
	undef) = split(/[,\*]/ , $_[0]);
	$m{'pvt.gtod'} = $tm;
}

sub parse_GPGLL{
	(
	undef,
	undef,
	undef,
	undef,
	$m{'position.time'},
	$m{'position.status'},
	undef) = split(/[,\*]/ , $_[0]);
	$m{'position.gtod'} = $tm;
}

sub parse_GPGSA{
	(
	$m{'active_sat.mode'},
	$m{'active_sat.fix'},
	undef) = split(/[,\*]/ , $_[0]);
}

sub finish_record{ 
	system("clear");
	if (($m{'position.status'} eq "V") || ($m{'pvt.status'} eq "V")){
		print "no valid GPS fix: $tm\n";
	} else {
		foreach (sort keys %m){
			print "$_ -> $m{$_}\n";
		}
	}
 }
