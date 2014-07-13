#!/usr/bin/perl

# $CSK: sirftool.pl,v 1.37 2006/09/20 17:30:46 ckuethe Exp $

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

use GPS::Tools;
use GPS::SiRF::Lib;
use Time::HiRes		qw(gettimeofday usleep time);
use Time::Local;

use warnings;
use strict;

$| = 1;
$SIG{'INT'} = $SIG{'HUP'} = $SIG{'TERM'} = \&bye;
my ($sp, @p, $packet, %asyncmask, $errno, $buf, $x, $y);

my $PORT = "/dev/gps0";

my $log = 0;
my $logf;
my $quiet = 1;

while (@ARGV){
	if ($ARGV[0] eq '-v'){
		$quiet = 0;
		use GPS::SiRF::Decoders;
		shift @ARGV;
		next;
	}

	if ($ARGV[0] eq '-w'){
		shift @ARGV; 
		my $f = shift @ARGV; 
		die "No logfile specified!\n" unless ($f);
		open($logf, ">>" . ${f}) or die "Can't open logfile '${f}': $!\n";
		$log = 1;
	}
}

# SiRF boots up at 4800 bps
$sp = init_serial($PORT, 4800);
print "serial port opened\n";
# knock it up a notch... bam!
sirf_sync_serial($sp, "sirf", 57600);

usleep(250000);
$sp->read_const_time(100);
$sp->read(1024);

#sirf_cold_debug($sp);
print "."; usleep(50000);
sirf_disable_tricklepower($sp);
print "."; usleep(50000);
sirf_enable_tracker($sp);
print "."; usleep(50000);
sirf_enable_sbas($sp);
print "!\n";

getpacket($sp);

bye();

###########################################################################
sub getpacket{
	my @x = (0,0);
	my $sp = $_[0];
	my $buf = "";
	my $r = 1;
	my ($len, $body, $cksum, $cx, $t, $pkt, $z, $x);
	my ($tmr, $n) = (0, 147);
	$sp->read_const_time(100);

	while ($r) {
		@x = $sp->read(1024);
		if ($x[0]){
			$buf .= $x[1];
		}

		while ($buf =~ /(\xa0\xa2.+?\xb0\xb3)(.*)/gism){
			
			$packet = $1;
			$z = sprintf ("matched %d bytes in %d byte buffer\n", length($packet), length($buf));
			$buf = $2;
			syswrite($logf, $packet) if ($log);
			if ($quiet){
				$x = sirf_packet_type($packet);
				printf ("%14.5f %s\n", time(), sirf_packet_name(sirf_packet_type($packet)));
			} else {
				parse_packet_sirf($packet);
			}
		}

		$tmr = (int(time()) % 300);
		# Query 132 Answer 6 = software version
		do{ sirf_runquery($sp, 132); $n = 147; } if (($tmr == 45) && ($n == 132));
		# Query 146 Answer 14 = Almanac
		do{ sirf_runquery($sp, 146); $n = 144; } if (($tmr == 30) && ($n == 146));
		# Query 147 Answer 15 = Ephemeris
		do{ sirf_runquery($sp, 147); $n = 146; } if (($tmr == 15) && ($n == 147));

	}
}

### sirf_nmeactl - twiddle the various nmea sentences that may be emitted
### input: which var to modify, a flag to set/get the var, and the rate
### output: nothing
### return: the packet to write to make the requested change
sub sirf_nmeactl{
	my ($m, $q, $r, undef) = @_;
	my %h = qw(GGA 0 GLL 1 GSA 2 GSV 3 RMC 4 VTG 5);
	if ($q =~ /^get$/i){
		$q = 1;
	} else {
		$q = 0;
	}
	$r = 0 if ($q);

	#MsgID,set/get,rate
	my $packet = sprintf("PSRF103,%02d,%02d,%02d,01",$h{$m},$r, $q);
	$packet = sprintf('$%s*%s', $packet, checksum_nmea($packet)) . "\x0d\x0a";
	return $packet;
}

### sirf_nmeadbg - control NMEA debugging info
### input: a flag to turn debugging off or on
### output: nothing
### return: the packet to write to make the requested change
sub sirf_nmeadbg{
	my ($q, undef) = @_;
	if ( ($q =~ /^on$/i) || ($q =~ /^true$/i) || ($q =~ /^yes$/i) || ($q != 0)){
		$q = 1;
	} else {
		$q = 0;
	}

	my $packet = sprintf("PSRF105,%d", $q);
	$packet = sprintf('$%s*%s', $packet, checksum_nmea($packet)) . "\x0d\x0a";
	return $packet;
}
