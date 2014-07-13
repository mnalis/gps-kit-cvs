# $CSK: Tools.pm,v 1.33 2006/09/19 20:37:00 ckuethe Exp $

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

package GPS::Tools;
use POSIX;
use Math::Trig;
use strict;
use warnings;

use Time::HiRes qw(usleep time);
use Device::SerialPort;
use Exporter;
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(init_serial sirf_setspeed bye hexdump sum is_invalid_nmea is_invalid_garmin is_invalid_sirf checksum_nmea checksum_garmin checksum_sirf floatfix int2signed ecef2lla lla2ecef factorial) ;

my $sp;

return 1;

### init_serial - configure the serial port for use
### input: name of tty device
### output: nothing
### return: a serial port object
sub init_serial{
	my $PORT = $_[0];
	die "Invalid port\n" unless defined($PORT);

	my $SPEED = 9600;
	if (defined($_[1]) && $_[1]){
		$SPEED = $_[1];
	}
	$sp = Device::SerialPort->new ($PORT) || die "Can't open $PORT: $!\n";
	($SPEED == $sp->baudrate($SPEED))	|| die "failed setting baudrate $SPEED\n";
	$sp->parity("none")	|| die "failed setting parity\n";
	$sp->databits(8)	|| die "failed setting databits\n";
	$sp->stopbits(1)	|| die "failed setting stopbits\n";
	$sp->handshake("none")	|| die "failed setting handshake\n";
#	$sp->read_const_time(100);
#	$sp->read_char_time(1);

	return $sp;
}

### sirf_setspeed - set the primary serial port speed
### input: a port descriptor and speed
### output: nothing
### return: 0 if unable to set speed, 1 if able to
sub sirf_setspeed{
	my %s = qw(1200 1 2400 1 4800 1 9600 1 19200 1 38400 1 57600 1 115200 1);
	my ($sp, $speed, undef) = @_;
	my $packet = "\xa0\xa2";

	return 0 unless (defined($s{$speed}));

	my $str = "\x86";
	#speed, data, stop, parity, reserved
	$str .= pack("N C C C C", ($speed,8,1,0,0));
	
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	foreach (sort {$b <=> $a} keys %s){
		$sp->baudrate($_);
		usleep(10000);
		$sp->baudrate($_);
		$sp->write($packet);
	}
	$sp->baudrate($speed);
	usleep(10000);
	$sp->baudrate($speed);
	return 1;
}

### bye - cleanup routine. close fds, ttys, etc.
### input: nothing
### output: nothing
### return: nothing
sub bye{
	#do cleanup stuff here
	eval {
		$sp->close();
		undef $sp;
	};
	die "exiting.\n"
}

### hexdump - do a standard hexdump
### input: a string to be hexdumped
### output: nothing
### return: the hexdumped string
sub hexdump{
        my $packet = $_[0];
        $packet = unpack("H*", $packet);
        $packet =~ s/(\S{2})/$1 /g;
        $packet =~ s/(\S{2} \S{2} \S{2} \S{2})/$1 /g;
        $packet =~ s/(\S{2} \S{2} \S{2} \S{2}  \S{2} \S{2} \S{2} \S{2}  )/$1\n/g;
	return $packet;
}

### sum - sum an array
### input: an array
### output: nothing
### return: the sum of the array elements.
sub sum{
	my @x = @_;
	my $r = 0;
	while (@x){
		$r += shift @x;
	}
	return $r;
}

### checksum_nmea - do the checksum for an NMEA sentence
### input: an NMEA sentence, without $ or * delimiters
### output: nothing
### return: the checksum string
sub checksum_nmea{
        my ($packet, undef) = @_;

        my $c = 0;
        foreach (split(//, $packet)){
                $c ^= ord($_);
        }
        $c &= 0xff;
        return sprintf("%02X", $c);
}

### checksum_garmin - do the checksum for a garmin packet
### input: the string to be checksummed (type + len + body)
### output: nothing
### return: the calculated checksum
sub checksum_garmin{
	my ($packet, undef) = @_;

	my $c = 0;
	foreach (unpack("C*", ($packet))){
		$c += $_;
	}
	$c &= 0xff;
	$c = (256 - $c) & 0xff;
	$c &= 0xff;
	return $c;
}

### checksum_sirf - do the checksum for a SiRF packet
### input: the body of a SiRF packet
### output: nothing
### return: the checksum of the packet
sub checksum_sirf{
	my ($packet, undef) = @_;
	my $c = 0;
	foreach (unpack("C*", ($packet))){
		$c += $_;
	}
	$c &= 0xffff;
	return $c;
}

### is_invalid_garmin - check the validity of a garmin packet
### input: an unescaped packet
### output: nothing
### return: 0 if valid, otherwise the number of the failed test
sub is_invalid_garmin{
	my ($packet, undef) = @_;
	my ($p_type, $p_len, $p_body, $p_sum, $c);

	return 1 unless defined($packet);
	return 2 unless ($packet =~ /\x10(.)(.)(.+?)(.)\x10\x03/ism);

	($p_type, $p_len, $p_body, $p_sum) = ($1, $2, $3, $4);

	$c = checksum_garmin($p_type . $p_len . $p_body);
	$p_sum = ord($p_sum);
	
	if ($c == $p_sum){
		return 0;
	} else {
		return 3;
	}
}

### is_invalid_nmea - check the validity of an NMEA sentence
### input: a complete NMEA sentence, 
### output: nothing
### return: 1 if message is valid, 0 otherwise
sub is_invalid_nmea{
        my ($packet, undef) = @_;

	return 1 unless defined($packet);
	return 2 unless ($packet =~ /^\$(.+)\*(\S{2})\s*$/ism);
        my $c = $2;
	$packet = $1;
	return ($c eq checksum_nmea($packet))?0:3;
}

### is_invalid_sirf - check the validity of a SiRF packet
### input: a packet
### output: nothing
### return: 0 if valid, or the number of the failed test
sub is_invalid_sirf{
	my ($packet, undef) = @_;
	return 1 unless defined($packet);

	return 2 unless ($packet =~ /\xa0\xa2(..)(.*)(..)\xb0\xb3/gism);
	my ($len, $body, $cksum) = ($1, $2, $3);

	$len = unpack("n", $len);
	return 3 unless ($len == length($body));

	my $cx = checksum_sirf($body);
	$cksum = unpack("n", $cksum);
	return ($cx == $cksum)?0:4;
}

### floatfix - fix up SiRF's busted-ass data encoding
### input: an 8byte SiRF encoded double or 4 byte SiRF encoded float
### output: nothing
### return: something that can be fed to *printf("%f",$var) ... ieee754, i hope
sub floatfix{
	my ($in, undef) = @_;
	my $l = length($in);
	
	# this is i386 (LE LP32) magic. work needed for all other cores.
	if ($l == 8){
		$in = pack('C*', (unpack('C*', $in))[3,2,1,0,7,6,5,4]);
		$in = unpack('d', $in);
	} elsif ($l == 4){
		$in = unpack('f', reverse $in);
	} else {
		$in = 0;
	}

	return $in;
}

### int2signed - turn an unsigned integer into a signed integer.
### input: an unsigned quantity and its length in bytes
### output: nothing
### return: the same bits as the input, but interpreted as a signed number
sub int2signed{
	my ($i, $l, undef) = @_;
	$l = 4 unless (defined($l) && ($l > 0));
	$l *= 8;

	my $x = (1 << ($l - 1)) - 1;
	if ($i > $x){
		$i = $i - (2 * $x) - 2;
	}
	return $i;
}

### ecef2lla - Convert ECEF (cartesian) coordinates to WGS84
### input: X Y Z in meters
### output: nothing
### return: a 3 element vector of latitude, longitude and altitude
sub ecef2lla{
	my ($A, $B, $E, $F, $P, $T, $N, $X, $Y, $Z, $lat, $long, $alt);
	($X, $Y, $Z, undef) = @_;

	$A = 6378137;
	$B = 6356752.3142;

	$E = (($A**2 - $B**2)/($A**2));
	$F = (($A**2 - $B**2)/($B**2));

	$P = sqrt( $X**2 + $Y**2);

	eval {
		$T = atan(($Z * $A)/($P * $B));

		$lat = atan(($Z + $F * $B * (sin $T) **3) /
			($P - $E * $A * (cos $T) **3));

		$long = atan( $Y / $X );

		$N = ($A **2) / sqrt(
		($A **2)*((cos $lat) **2) +
		($B **2)*((sin $lat) **2) );

		$alt = ($P / cos $lat) - $N;
	};

	return (0,0,0) if ($@);
	return(rad2deg($lat), rad2deg($long)-180, $alt);
}

### lla2ecef - Convert WGS84 coordinates to ECEF (cartesian)
### input: latitude and longitude in degrees and altitude meters
### output: nothing
### return: a 3 elemnt vector of X Y Z in meters
sub lla2ecef{
	my ($lat, $long, $alt, undef) = @_;

	my ($A, $B, $X, $Y, $Z, $N);
	$A = 6378137;
	$B = 6356752.3142;
	$lat  = deg2rad($lat);
	$long = deg2rad($long);

	$N = ($A **2) / sqrt(
	($A **2)*((cos $lat) **2) +
	($B **2)*((sin $lat) **2) );

	$X = ($N + $alt) * cos($lat) * cos($long);
	$Y = ($N + $alt) * cos($lat) * sin($long);
	$Z = (($B**2 / $A**2) * $N + $alt) * sin($lat);

	return($X, $Y, $Z);
}

sub factorial{
	my $n = int($_[0]);
	my $r = 1;

	if ($n > 1){
		$r = $n * factorial($n - 1);
	}
	return $r;
}
