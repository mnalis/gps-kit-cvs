# $CSK: Decoder_041.pm,v 1.13 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_041;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_41);

return 1;

# This will really only work for GSW2 >= 232.000.000. In older firmware this
# message is generated by the chipset but it's mostly full of garbage. Also,
# lines marked SDO are only valid for SiRFDRive systems. In the interests of
# completeness, I decode the whole packet into useful perl quantities, and let
# you decide if you want to process them. The printer tries to be smart about
# not displaying invalid measurements though.

sub sirf_packet_41{
	my ($packet, $quiet, $tm, undef) = @_;
	
	my @x = unpack("n  n  n  N  n  C  C  C  C  n  N  N  N  N  N  C  n  n  n  n  n  N  N  N  n  N  N  N  N  N  n  n  C  C  C", $packet);
#element:               0           4           8           12          16          20          24          28          32
	my $s = ($x & 0x0040)? 1 : 0;
	# GPS TOW milliseconds -> seconds
	$x[3] /= 1000;

	# UTC milliseconds -> seconds
	$x[9] /= 1000;

	#lat/long * 1e7
	$x[11] = int2signed($x[11], 4) / 1e7;
	$x[12] = int2signed($x[12], 4) / 1e7;

	#altitude in centimetres
	$x[13] = int2signed($x[13], 4) / 100;
	$x[14] = int2signed($x[14], 4) / 100;

	# speed in cm/s and course in 100th's of a degree
	$x[16] /= 100;
	$x[17] /= 100;

	# climb rate in cm/s and heading rate in 100th's of a degree/s
	$x[19] /= 100;
	$x[20] /= 100;	#SDO

	# Position X Y, Time, Velocity error
	$x[21] /= 100;	#SDO
	$x[22] /= 100;	#SDO
	$x[23] /= 100;	#SDO
	$x[24] /= 100;	#SDO

	# Position X Y, Time, Velocity error
	$x[25] /= 100;
	$x[26] /= 100;	#SDO
	$x[27] /= 100;
	$x[28] /= 100;	#SDO
	$x[31] /= 100;	#SDO

	#hdop
	$x[33] /= 5;	#SDO

	if (!$quiet){
		print("$tm Geodetic Navigation Data [41]\n");

		printf("\tNav Validity: %s\n", d41_f1($x[0]));
		printf("\tNav Type: 0x%04x - %s\n", $x[1], d41_f2($x[1]));

		printf("\tExtended Week Number %d\n", $x[2]);
		printf("\tTOW: %-10.3f\n", $x[3]);

		printf("\tUTC Time: %02d/%02d/%02d %02d:%02d:%06.3f\n", $x[4], $x[5], $x[6], $x[7], $x[8], $x[9] );
		printf("\tSVs Used in Fix: %s\n", d41_f10($x[10]));

		printf("\tLatitude: %f\n", $x[11]);
		printf("\tLongitude: %f\n", $x[12]);

		printf("\tAltitude Above Elipsoid: %.2fm\n", $x[13]);
		printf("\tAltitude Above Mean Sea Level: %.2fm\n", $x[14]);

		printf("\tDatum: %s\n", d41_f15($x[15]));

		printf("\tSpeed Over Ground: %.2fm/s\n", $x[16]);
		printf("\tCourse Over Ground: %.2fdeg\n", $x[17]);

		printf("\tMagnetic Variation: %d\n", $x[18]);	# not implemented. possibly invalid
		printf("\tClimb Rate: %.2fm/s\n", $x[19]);
		printf("\tHeading Rate: %.2fdeg/s\n", $x[20]) if ($s);

		printf("\tEHPE: %.2fm\n", $x[21]) if ($s);
		printf("\tEVPE: %.2fm\n", $x[22]) if ($s);
		printf("\tETPE: %.2fs\n", $x[23]) if ($s);
		printf("\tEHVE: %.2fm/s\n", $x[24]) if ($s);

		printf("\tClock Bias: %.2fm/s\n", $x[25]);
		printf("\tClock Bias Error: %.2fm/s\n", $x[26]) if ($s);
		printf("\tClock Drift: %.2fm/s\n", $x[27]);
		printf("\tClock Drift Error: %.2fms/\n", $x[28]) if ($s);

		printf("\tDist after reset: %dm\n", $x[29]) if ($s);
		printf("\tDist error: %dm\n", $x[30]) if ($s);
		printf("\tHeading error: %.2fdeg\n", $x[31]) if ($s);

		printf("\tSVs: %d\n", $x[32]);
		printf("\tHDOP: %.1f\n", $x[33]);
		printf("\tReserved: %d\n", $x[34]);
	}
	return @x;
}

sub d41_f1{
	my $x = shift;
	return "Valid" unless ($x);
	my @w = ();
	($x & 0x0001) && push (@w, "Fix not validated");		#bit 0
	# officially, these are "reserved"
	($x & 0x0002) && push (@w, "EHPE Limits Exceeded");		#bit 1
	($x & 0x0004) && push (@w, "EVPE Limits Exceeded");		#bit 2
	# these are only valid for SiRFDrive
	($x & 0x0008) && push (@w, "DR Data Invalid");			#bit 3
	($x & 0x0010) && push (@w, "DR Cal Invalid");			#bit 4
	($x & 0x0020) && push (@w, "GPS-based Cal Unavailable");	#bit 5
	($x & 0x0040) && push (@w, "DR Position Invalid");		#bit 6
	($x & 0x0080) && push (@w, "DR Heading Invalid");		#bit 7
	# this is only valid for SiRFNav
	($x & 0x8000) && push (@w, "No Tracker Data Available");	#bit 15
	# and this is my catch-all
	($x & 0x7f00) && push (@w, "Unknown Error");
	return join(", ", @w);
}

sub d41_f2{
	my $x = shift;
	my @w = ();
	my $t;

	$t = ("No Nav", "1 SV KF", "2 SV KF", "3 SV KF (2D)", "4+ SV (3D)", "LSq 2D", "LSq 3D", "0 SV (DR)")[($x & 0x0007)] . " Solution";
	push(@w, $t);

	# now marked as reserved
	$t = sprintf("Trickle Power %s", ($x & 0x0008)? "On" : "Off");
	push(@w, $t);

	$t = ("No Altitude Hold", "Filter Altitude", "User Altitude Used", "User Altitude Forced")[(($x >> 4) & 0x0003)];
	push(@w, $t);

	$t = sprintf("SiRFDrive %s", ($x & 0x0040)? "On" : "Off");
	push(@w, $t);

	$t = sprintf("DGPS Corrections %s", ($x & 0x0080)? "On" : "Off");
	push(@w, $t);

	$t = sprintf("%s", ($x & 0x0100)? "Sensor-based DR" : "");
	push(@w, $t) if ($t);

	$t = sprintf("%s", ($x & 0x0200)? "Solution Validated" : "");
	push(@w, $t) if ($t);

	$t = sprintf("%s", ($x & 0x0400)? "VEL DR Timeout" : "");
	push(@w, $t) if ($t);

	$t = sprintf("%s", ($x & 0x0800)? "Edited by UI" : "");
	push(@w, $t) if ($t);

	$t = sprintf("%s", ($x & 0x1000)? "Velocity Valid" : "");
	push(@w, $t) if ($t);

	$t = sprintf("%s", ($x & 0x2000)? "Altitude Hold Disabled" : "");
	push(@w, $t) if ($t);

	$t = ("GPS-only solution", "DR Calibration from GPS", "DR Sensor Error", "DR in Test Mode")[(($x >> 14) & 0x0003)];
	push(@w, $t);

	return join(", ", @w);
}

sub d41_f10{
	my $x = shift;
	my @w = ();

	for (my $i = 0; $i < 32; $i++){
		push (@w, sprintf("%d", $i+1)) if (($x & (1<<$i)));
	}

	return join(" ", @w);
}

sub d41_f15{
	my %w = qw(0 WGS-84 21 WGS-84 178 Tokyo-Mean 179 Tokyo-Japan 180 Tokyo-Korea 181 Tokyo-Okinawa );
	my $x = shift;
           $x = (defined($w{$x})) ? $w{$x} : "Unknown";
        return sprintf("%s (%d)", $x, $_[0]);
}