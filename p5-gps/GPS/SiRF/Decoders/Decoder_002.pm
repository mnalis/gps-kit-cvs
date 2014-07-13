# $CSK: Decoder_002.pm,v 1.5 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_002;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_2);

return 1;

sub sirf_packet_2{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("N N N n n n C C C n N C C12", $packet);

	$x[0] = unpack("l", pack("L", $x[0]));	
	$x[1] = unpack("l", pack("L", $x[1]));	
	$x[2] = unpack("l", pack("L", $x[2]));	

	$x[3] = unpack("s", pack("S", $x[3]));	
	$x[4] = unpack("s", pack("S", $x[4]));	
	$x[5] = unpack("s", pack("S", $x[5]));	

	if (!$quiet){
		print "$tm Navigation Solution [2]\n";
		printf ("\tECEF X/Y/Z: %d/%d/%d m\n", $x[0], $x[1], $x[2]);
		printf ("\tWGS84 lat: %5.5f long: %5.5f alt: %5.3f m\n", ecef2lla($x[0], $x[1], $x[2]));
		printf ("\tVelocity X/Y/Z: %5.3f/%5.3f/%5.3f m/s\n", $x[3]/8, $x[4]/8, $x[5]/8);
		printf ("\tMode 1: 0x%02x %s\n", $x[6], sirf_flags_2_1($x[6]) );
		printf ("\tHDOP: %.1f\n", $x[7]/5);
		printf ("\tMode 2: 0x%02x %s\n", $x[8], sirf_flags_2_2($x[8]));
		printf ("\tGPS Week: %d\n", $x[9]);
		printf ("\tGPS TOW: %8.2f\n", $x[10]/100);
		printf ("\tSV's in fix: %d\n", $x[11]);
		for(my $i = 0; $i < 12; $i++){
			printf ("\tCh. %2d PRN: %d\n", $i+1, $x[$i+12]) if ($x[$i+12]);
		}
	}
	return @x;
}

sub sirf_flags_2_1{
	my ($flags, undef) = @_;
	my $w = "";
	my (@decode, $v);

	$w .= sprintf("TricklePower %s, ", ($flags & 0x08)?"on":"off");
	$w .= sprintf("DOP Mask %sExceeded, ", ($flags & 0x40)?"":"Not ");
	$w .= sprintf("%sDGPS Solution, ", ($flags & 0x80)?"":"Non-");

	$v = $flags & 0x07;
	@decode = ("No Solution",	"1 Satellite Solution",
	"2 Satellite Solution",		"3 Satellite Solution",
	"4+ Satellite Solution",	"2D Point Solution",
	"3D Point Solution",		"Dead Reckoning");
	$w .= sprintf("%s, ", $decode[$v]);
	
	$v = ($flags & 0x30) >> 4;
	@decode = ("No Altitude Hold", "Altitude Used From Filter",
	"Altitude Used From User", "User Altitude Forced");
	$w .= sprintf("%s, ", $decode[$v]);
	
	return $w;
}

sub sirf_flags_2_2{
	my ($flags, undef) = @_;
	my $w = "";

	$w .= sprintf("Solution %sValidated ", ($flags &  0x02)?"":"Not ");
	$w .= sprintf("%s", ($flags == 0x00)?"Invalid, ":"");
	$w .= sprintf("%s", ($flags == 0x01)?"DR Sensor Data, ":"");
	$w .= sprintf("%s", ($flags == 0x04)?"Using Dead Reckoning, ":"");
	$w .= sprintf("%s", ($flags == 0x08)?"Output Edited by UI, ":"");

	return $w;
}
