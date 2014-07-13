# $CSK: Decoder_031.pm,v 1.2 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_031;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_31);

return 1;

sub sirf_packet_31{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("C  C  C  N  C  n  n  n  C  C  n  n  n  C  n  n  n  C  n  C  n  C  n  d  d  d  C  d  n  C  d  C", $packet);
# offset:               00 01 02 03 07 08 10 12 14 15 16 18 20 22 23 25 27 29 30 32 33 35 36 38 46 54 62 63 71 73 74 82

	$x[23] = floatfix(substr($packet, 38, 8));
	$x[24] = floatfix(substr($packet, 46, 8));
	$x[25] = floatfix(substr($packet, 54, 8));
	$x[27] = floatfix(substr($packet, 63, 8));
	$x[30] = floatfix(substr($packet, 74, 8));

	if (!$quiet){
		print("$tm NavLib Initialization Data [31]\n");

		printf("\tAltitude Mode: %s\n", d31_f1($x[1]));
		printf("\tAltitude Source: %d\n", $x[2]);
		printf("\tAltitude: %dm\n", $x[3]);
		printf("\tDegraded Mode: %s\n", d31_f2($x[4]));
		printf("\tDegraded Timeout: %ds\n", $x[5]);
		printf("\tDead Reckoning Timeout: %ds\n", $x[6]);
		printf("\tTrack Smoothing Mode: %s\n", d31_f3($x[8]));
		printf("\tDGPS Selection: %s\n", d31_f4($x[13]));
		printf("\tDGPS Timeout: %d\n", $x[14]);
		printf("\tElevation mask: %0.1fdeg\n", $x[15]/10);
		printf("\tStatic Navigation Mode: %s\n", d31_f5($x[21]));
		printf("\tX Position: %+fm\n", $x[23]);
		printf("\tY Position: %+fm\n", $x[24]);
		printf("\tZ Position: %+fm\n", $x[25]);
		printf("\tPosition Init Source: %s\n", d31_f6($x[26]));
		printf("\tGPS Time: %f\n", $x[27]);
		printf("\tGPS Week: %d\n", $x[28]);
		printf("\tTime Init Source: %s\n", d31_f7($x[29]));
		printf("\tDrift: %f\n", $x[30]);
		printf("\tDrift Init Source: %s\n", d31_f8($x[31]));

		printf("\tReserved00: %d\n", $x[0]);
		printf("\tReserved01: %d\n", $x[7]);
		printf("\tReserved02: %d\n", $x[7]);
		printf("\tReserved03: %d\n", $x[8]);
		printf("\tReserved04: %d\n", $x[7]);
		printf("\tReserved05: %d\n", $x[10]);
		printf("\tReserved06: %d\n", $x[11]);
		printf("\tReserved07: %d\n", $x[12]);
		printf("\tReserved08: %d\n", $x[16]);
		printf("\tReserved09: %d\n", $x[17]);
		printf("\tReserved10: %d\n", $x[18]);
		printf("\tReserved11: %d\n", $x[19]);
		printf("\tReserved12: %d\n", $x[20]);
		printf("\tReserved13: %d\n", $x[22]);
	}
	return @x;
}

sub d31_f1{
	my @a = ("Last Known",  "User Input", "External");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "Unknown";
	return sprintf("%s (%d)", $x, $_[0]);
}

sub d31_f2{
	my @a = ("Direction Hold, Time Hold", "Time Hold", "Direction Hold", "Direction Hold", "Time Hold", "Degraded Mode Disabled");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "Unknown";
	return sprintf("%s (%d)", $x, $_[0]);
}
sub d31_f3{
	my @a = ("True", "False");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "WTF";
	return sprintf("%s (%d)", $x, $_[0]);
}

sub d31_f4{
	my @a = ("Always Try", "Always Require", "Never Try");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "Unknown";
	return sprintf("%s DGPS (%d)", $x, $_[0]);
}

sub d31_f5{
	my @a = ("True", "False");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "WTF";
	return sprintf("%s (%d)", $x, $_[0]);
}

sub d31_f6{
	my @a = ("ROM", "User", "SRAM", "Network Assisted");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "Unknown";
	return sprintf("%s Position (%d)", $x, $_[0]);
}

sub d31_f7{
	my @a = ("ROM", "User", "SRAM", "RTC", "Network Assisted");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "Unknown";
	return sprintf("%s Time (%d)", $x, $_[0]);
}

sub d31_f8{
	my @a = ("ROM", "User", "SRAM", "Calibration", "Network Assisted");
	my $x = $_[0];
	   $x = (defined($a[$x])) ? $a[$x] : "Unknown";
	return sprintf("%s Clock (%d)", $x, $_[0]);
}
