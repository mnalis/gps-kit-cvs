# $CSK: Decoders.pm,v 1.58 2006/09/07 15:22:57 ckuethe Exp $

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

package GPS::SiRF::Decoders;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;

use GPS::SiRF::Decoders::Decoder_002 ;
use GPS::SiRF::Decoders::Decoder_004 ;
use GPS::SiRF::Decoders::Decoder_005 ;
use GPS::SiRF::Decoders::Decoder_006 ;
use GPS::SiRF::Decoders::Decoder_007 ;
use GPS::SiRF::Decoders::Decoder_008 ;
use GPS::SiRF::Decoders::Decoder_009 ;
use GPS::SiRF::Decoders::Decoder_010 ;
use GPS::SiRF::Decoders::Decoder_011 ;
use GPS::SiRF::Decoders::Decoder_012 ;
use GPS::SiRF::Decoders::Decoder_013 ;
use GPS::SiRF::Decoders::Decoder_014 ;
use GPS::SiRF::Decoders::Decoder_015 ;
use GPS::SiRF::Decoders::Decoder_017 ;
use GPS::SiRF::Decoders::Decoder_018 ;
use GPS::SiRF::Decoders::Decoder_027 ;
use GPS::SiRF::Decoders::Decoder_028 ;
use GPS::SiRF::Decoders::Decoder_029 ;
use GPS::SiRF::Decoders::Decoder_030 ;
use GPS::SiRF::Decoders::Decoder_031 ;
use GPS::SiRF::Decoders::Decoder_041 ;
use GPS::SiRF::Decoders::Decoder_050 ;
use GPS::SiRF::Decoders::Decoder_052 ;
use GPS::SiRF::Decoders::Decoder_225 ;
use GPS::SiRF::Decoders::Decoder_255 ;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(parse_packet_sirf decode_how decode_sync_flags);
our %gps_ctx;

return 1;

### packet_parse_sirf - callback redirector for input packets
### input: a packet, possibly a quiet flag and an external timestamp
### output: nothing
### return: the array containing the words in the packet
sub parse_packet_sirf{
	my ($packet, $quiet, $tm, undef) = @_;
	my ($len, $body, $cksum, $cx, $t, $z);
	$packet =~ /\xa0\xa2(..)(.*)(..)\xb0\xb3/gism;
	$len = $1; $body = $2; $cksum = $3;
	$len = unpack("n", $len); $cksum = unpack("n", $cksum);

	$cx = checksum_sirf($body);
	$tm = time() unless (defined($tm));
	$tm = sprintf("%14.5f", $tm);
	$quiet = 0 unless (defined($quiet));
	$z .= sprintf("%f checksum %s\n", $tm, ($cx == $cksum)?"OK":"Failed ($cx : $cksum)");

	$body =~ /(.)(.*)/gism;
	($t, $body) = ($1, $2);
	$t = ord($t);
	$@ = "";
	my @rv = ();

	unless (is_invalid_sirf($packet)){
		eval {
			my $func = \&{"sirf_packet_$t"} ;
			@rv = &$func($body, $quiet, $tm);
			print "\n" . "-" x 40 . "\n" unless ($quiet);
		} ;
	}
	if (!$quiet && $@){
		print $z;
		$body = hexdump($body);
		printf("type: %d\n", $t);
		printf("%s\n", $body);
		print "$@\n";
		print "\n" . "-" x 40 . "\n";
	}
	return @rv;
}

sub decode_how{
	# handover word as a network long, parity stripped.
	my @how;
	$how[0] = $_[0] & 0x03;
	$how[1] = (($_[0] >> 2) & 0x07);
	$how[2] = ($_[0] & 0x20)? 1 : 0;
	$how[3] = ($_[0] & 0x40)? 1 : 0;
	$how[4] = (($_[0] >> 6) & 0x1ffff);
	# returns (fixup bits, subframe id, antispoofing, alert flag, x1_tow)
	return(@how);
}

sub decode_sync_flags{
	my ($flags, undef) = @_;
	my $w = "";

	$w .= "ACQ_SUCCESS "		if ($flags & 0x01);
	$w .= "DELTA_CARPHASE_VALID "	if ($flags & 0x02);
	$w .= "BIT_SYNC_DONE "		if ($flags & 0x04);
	$w .= "SUBFRAME_SYNC_DONE "	if ($flags & 0x08);
	$w .= "CARRIER_PULLIN_DONE "	if ($flags & 0x10);
	$w .= "CODE_LOCKED "		if ($flags & 0x20);
	$w .= "ACQ_FAILED "		if ($flags & 0x40);
	$w .= "GOT_EPHEMERIS "		if ($flags & 0x80);
	return $w;
}

sub prn2svn{
	# based on https://www.schriever.af.mil/gps/Current/as.txt this is a
	# mapping of pseudorandom noise code to space vehicle number. this
	# may change as SVs are taken in and out of service.
	# PRN19 = http://www.celestrak.com/GPS/NANU/2004/nanu.2004043.txt

	# SVN10 (PRN12) is retired, and being used for testing purposes
	# PRN12 = http://www.celestrak.com/GPS/NANU/1996/nanu.051-96086.txt

	# SVN17 (PRN17) will be retiring on 23 Feb 2005. PRN to be reused
	# PRN17 = http://www.celestrak.com/GPS/NANU/2005/nanu.2005022.txt
	my %map = (	1 => 32,	2 => 61,	3 => 33,
	4 => 34,	5 => 35,	6 => 36,	7 => 37,
	8 => 38,	9 => 39,	10 => 40,	11 => 46,
	12 => 10,	13 => 43,	14 => 41,	15 => 15,
	16 => 56,	17 => 17,	18 => 54,	19 => 59,
	20 => 51,	21 => 45,	22 => 47,	23 => 60,
	24 => 24,	25 => 25,	26 => 26,	27 => 27,
	28 => 44,	29 => 29,	30 => 30,	31 => 31);
	my $r = shift;
	$r = (defined($map{$r})) ? $map{$r} : 0;
	return $r;
}
