# $CSK: Decoder_028.pm,v 1.5 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_028;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_28);

return 1;

sub sirf_packet_28{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("C N C d d f d n C C10 n n n C C", $packet);
	my $a;

	$x[3] = floatfix(substr($packet, 6, 8));
	$x[4] = floatfix(substr($packet, 14, 8));
	$x[5] = floatfix(substr($packet, 22, 4));
	$x[6] = floatfix(substr($packet, 26, 8));
	my @rv = @x;

	if (!$quiet){
		print("$tm NavLib Measurement Data [28]\n");
		printf("\tChannel %d\n", $x[0]);
		printf("\tTime Tag %d\n", $x[1]);
		printf("\tPRN %d\n", $x[2]);
		printf("\tGPS Software Time %fms\n", $x[3]);
		printf("\tPseudorange %fm\n", $x[4]);
		printf("\tCarrier Frequency %fm/s\n", $x[5]);
		printf("\tCarrier Phase %fm\n", $x[6]);
		printf("\tTime In Track %dms\n", $x[7]);
		printf("\tSync Flags %d (SV State %s)\n", $x[8], GPS::SiRF::Decoders::decode_sync_flags($x[8]));
		printf("\tDelta Range Interval %dm\n", $x[19]);
		printf("\tMean Delta Range Time %dms\n", $x[20]);
		printf("\tExtrapolation Time %dms\n", $x[21]);
		printf("\tPhase Error Count %d\n", $x[22]);
		printf("\tLow Power Count %d\n", $x[23]);
		@x = @x[9..18]; $a = sum(@x) / 10;
		printf("\tSNR %d %d %d %d %d %d %d %d %d %d (average %3.1f)\n", @x, $a);
	}
	return @rv;
}
