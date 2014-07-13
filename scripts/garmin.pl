#!/usr/bin/perl

# $CSK$

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
use Time::HiRes qw( gettimeofday );
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
$sp->baudrate(9600)	|| die "failed setting baudrate";
$sp->parity("none")	|| die "failed setting parity";
$sp->databits(8)	|| die "failed setting databits";
$sp->handshake("none")	|| die "failed setting handshake";

open(DEV, "+<$PORT") || die "Cannot open $PORT: $!\n";
select((select(DEV), $| = 1)[0]);
select((select(STDOUT), $| = 1)[0]);


###########################################################################
sub bye{
	#do cleanup stuff here
	close DEV;
	undef $sp;
	die "Caught signal... exiting.\n"
}

sub read_packet{
	my ($type, $payload)
	my ($rl, $len, $c, $ck, $p);

	#255 payload bytes, 6 header/trailer bytes, doubled for escaped chars
	($rl, $p) = $sp->read((255 + 6)*2);
	$p = substr($p,1,length($p)-3)
	$payload =~ s/\x10\x10/\x10/g;
	$type = substr($p,0,1);
	$len = substr($p,1,1);
	$ck =  substr($p,-1,1);
	$payload = substr($p,2,length($p)-3);
	
	$c = chksum($type, $len, $payload)
	if ($ck == $c ){
		ackpacket($type, 1);
		return ($type, $payload);
	} else {
		ackpacket($type, 0);
		return (undef, undef);
	}
}

sub send_packet{
	my ($type, $payload, undef) = @_;
	my ($len, $c);

	$len = pack("C",length($payload));
	$type = pack("C", $type)
	$c = chksum($type, $len, $payload)
	$packet = $len . $payload . $c;
	$packet =~ s/(\x10)/\1\1/g;
	$packet = "\x10" . $type . $packet . "\x10\x03";
	print DEV $packet;
}

sub send_ack_packet{
	my ($payload, $ack) = @_;
	my ($len, $c, $type);

	$len = "\x01";
	if ($ack){
		# ACK
		$type = "\x06";
	} else {
		# NAK
		$type = "\x15";
	}
	$c = chksum($type, $len, $payload)
	$packet = $len . $payload . $c;
	$packet =~ s/(\x10)/\1\1/g;
	$packet = "\x10" . $type . $packet . "\x10\x03";
	print DEV $packet;
}

sub read_ack_packet{
	my ($target, undef) = @_;
	my ($rl, $len, $c, $ck, $p, $type, $payload);

	#255 payload bytes, 6 header/trailer bytes, doubled for escaped chars
	($rl, $p) = $sp->read((255 + 6)*2);
	$p = substr($p,1,length($p)-3)
	$payload =~ s/\x10\x10/\x10/g;
	$type = substr($p,0,1);
	$len = substr($p,1,1);
	$payload = substr($p,2,1);
	$ck =  substr($p,-1,1);
	$c = chksum($type, $len, $payload)
	
	return -1 if (($type ne "\x06") && ($type ne "\x15"));
	return -1 if ($payload ne $target);
	return ($type eq "\x06") ? 1 : 0;
}

sub chksum{
	my ($type, $len, $payload, undef) = @_;
	my $c = "\0";

	foreach (($type, $len, unpack("C*", $payload))){
		$c ^= $_ ;
	}
	
	$c = 256 - $c;
	return $c;
}
