# $CSK: Decoder_030.pm,v 1.5 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_030;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_30);

return 1;

sub sirf_packet_30{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("C d d d d d d d d f C N N f", $packet);

	$x[1] = floatfix(substr($packet,  1, 8));
	$x[2] = floatfix(substr($packet,  9, 8));
	$x[3] = floatfix(substr($packet, 17, 8));
	$x[4] = floatfix(substr($packet, 25, 8));
	$x[5] = floatfix(substr($packet, 33, 8));
	$x[6] = floatfix(substr($packet, 41, 8));
	$x[7] = floatfix(substr($packet, 49, 8));
	$x[8] = floatfix(substr($packet, 57, 8));
	$x[9] = floatfix(substr($packet, 65, 4));
	$x[13] = floatfix(substr($packet, 74, 4));

	if (!$quiet){
		print("$tm NavLib SV State Data [30]\n");
		printf("\tPRN %d\n", $x[0]);
		printf("\tGPS Time %fs\n", $x[1]);
		printf("\tX Position %fm\n", $x[2]);
		printf("\tY Position %fm\n", $x[3]);
		printf("\tZ Position %fm\n", $x[4]);
		printf("\tX Velocity %fm/s\n", $x[5]);
		printf("\tY Velocity %fm/s\n", $x[6]);
		printf("\tZ Velocity %fm/s\n", $x[7]);
		printf("\tClock Bias %fsec\n", $x[8]);
		printf("\tClock Drift %fsec/sec\n", $x[9]);
		printf("\tEphemeris Flags %d (SV State %s)\n", $x[10],
			("not valid", "calculated from ephemeris", "calculated from almanac")[$x[10]]);
		printf("\tReserved 1 0x%08x\n", $x[11]);
		printf("\tReserved 2 0x%08x\n", $x[12]);
		printf("\tIonospheric Delay %dm\n", $x[13]);
	}
	return @x;
}
