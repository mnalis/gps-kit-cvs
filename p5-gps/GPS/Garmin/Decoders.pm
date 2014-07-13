# $CSK: Decoders.pm,v 1.6 2006/09/07 15:22:54 ckuethe Exp $

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

package GPS::Garmin::Decoders;

use GPS::Garmin::Lib;
use Time::HiRes qw( gettimeofday usleep time);

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
%EXPORT_TAGS = ( all => [ qw(packet_parse packet_dump) ] );
Exporter::export_tags('all');
Exporter::export_ok_tags('all');

return 1;

### packet_parse - callback redirector for input packets
### input: an unescaped packet
### output: nothing
### return: nothing
sub packet_parse{
	my ($packet, undef) = @_;
	my ($p_type, $r);

	return 0 unless ($packet =~ /(\x10[^\x10\x03].+?\x10\x03)/ism);
	$packet = $1;
	$p_type = packet_type($packet);
	# weak attempt at resynchronization
	if ($p_type == 3){
		$packet = substr($packet,2);
		$p_type = packet_type($packet);
	}
	if ($p_type == 16){
		$packet = substr($packet,1);
		$p_type = packet_type($packet);
	}


	$@ = "";
	eval { $func = \&{"packet_type_$p_type"} ; &$func($packet);};

	packet_dump($packet) if ($@);
	return 0 if (is_invalid_garmin($packet));
	return 1;
}

### packet_dump - dump the contents of the packet to screen as a hex string
### input: an unescaped packet
### output: the decoded packet
### return: nothing
sub packet_dump{
	my ($rl, $v, $packet);
	$packet = $_[0];
	$rl = length($packet) - 6;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$type = packet_type($packet);
	$typedecode = pid2txt($type);
	$packet = hexdump($packet);
	printf("%f [len %d, type %s, %svalid]\n%s\n", time(), $rl, $typedecode, $v, $packet);
}

### packet_type_X - type-specific decoders
### input: an unescaped packet
### output: a verbose packet decode
### return: nothing

sub packet_type_6 { # ACK
	my ($p, $rl, $v, $t);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	if ($rl == 1){
		$p = unpack("C", $3);
	} else {
		$p = unpack("S", $3);
	}
	$t = pid2txt($p);
	printf("%f ACK of packet type %d (%s) [len %d, %svalid]\n", time(), $p, $t, $rl, $v);
}

sub packet_type_21 { 
	my ($p, $rl, $v, $t);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	if ($rl == 1){
		$p = unpack("C", $3);
	} else {
		$p = unpack("S", $3);
	}
	$t = pid2txt($p);
	printf("%f NAK of packet type %d (%s) [len %d, %svalid]\n", time(), $p, $t, $rl, $v);
}

sub packet_type_254 {
	my ($p, $rl, $v, $t);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

	printf("%f %s [len %d, %svalid]\n", time(), $t, $rl, $v);
}

sub packet_type_255 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));
	
	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("v v A*", $3);
	$i = sprintf("%s (0x%x)", $x[2], $x[0]);
	printf("%f %s = %s [len %d, %svalid]\n", time(), $t, $i, $rl, $v);
}

sub packet_type_13 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("v v V", $3);
	$i = sprintf("
	type 0x%04x
	subtype 0x%04x
	gpstime %08d", @x);
	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_54 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("V V c", $3);
	$i = sprintf("
	counter: %u
	junk: 0x%08x
	svn: %d", @x);
	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_56 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("d d V V V V V V c", $3);
	$i = sprintf("
	pseudorange: %g
	timeofweek: %g
	phasecounter: %u
	tracked: %u
	integrated phase: %u
	counter511500: %u
	delta_f: %u
	signal: %u
	svn: %d", @x);
	printf("%f %s: [len %d, %svalid] * %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_20 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

packet_dump($p);
	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/gism;
@x =	unpack("N N N V N N N d d N N N N N N N N c c N", $3);
@x = (@x)[17, 7, 3];
#$x[1] -= $x[3];
#$x[2] = (($x[2] << 9) & 0xffffffff) | ($x[4] & ((1<<9)-1));
	$i = sprintf("
	typeoffix: %u
	tow: %f
	tow2: %u"
	, (@x)[0..2]);

	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_39 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("v", $3);
	$i = sprintf("\n\tmagic: %d" , @x);

	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_55 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("v v v v v d V d v c", $3);
	$i = sprintf("
	c1: %u
	flags1: %04x
	c2: %u
	delta_f: %d
	countdown: %u
	pseudorange: %g
	c511: %u
	timeofweek: %g
	flags2: %04x 
	svn: %d" , @x);

	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_22 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("f d f f c", $3);
	$i = sprintf("
	delta_pseudorange: %f
	pseudorange: %g
	flags1: %f
	flags2: %f
	svn: %d" , @x);

	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_51 {
	my ($p, $rl, $v, $t, $i, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));

packet_dump($p);
	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	@x = unpack("f f f f v d d d f f f f v V", $3);
	$i = sprintf("
	altitude: %f
	Est Sph Err: %f
	Est Hor Err: %f
	Est Ver Err: %f
	Fix Type: %u
	timeofweek: %g
	latitude: %g
	longitude: %g
	V e: %f
	V n: %f
	V u: %f
	Ellipsoid ht: %f
	leapsec2utc: %u" , @x);

	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}

sub packet_type_26 {
	my ($p, $rl, $v, $t, $i, $b, $j, @x);
	($p, undef) = @_;
	$v = is_invalid_garmin($packet) ? "" : "in";
	$rl = length($p) - 6;
	$t = pid2txt(packet_type($p));
	$p =~ /\x10(.)(.)(.+?)(.)\x10\x03/;
	$p = $3;

	$i= "";
	for ($j = 0; $j < 12; $j++){
	$b = substr($p, 12, 12*$j);
	@x = unpack("c c v c c c", $b);
	$x[0] &= 2047;
	$i .= sprintf("
    channel: %d
        svn: %d
        elevation: %d
        quality: %u
        tracking: %u
        status : %02x
        junk: %02x"
	, $j+1,  @x);
	}
	printf("%f %s: [len %d, %svalid] %s\n", time(), $t, $rl, $v, $i);
}
