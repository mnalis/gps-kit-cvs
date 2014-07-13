# $CSK: Decoder_005.pm,v 1.7 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_005;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_5);

return 1;

sub sirf_packet_5{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("N n n N n n N N N N n C10 n n", $packet);
	my $pi = 3.1415926535898;
	my $magic = (1000/(4*$pi))/(2**16);
	my $a;

	$x[9] = int2signed($x[9], 4) * $magic;
	if (!$quiet){
		print "$tm Raw Tracker Output (obsolete) [5]\n";
		printf("\tChannel %d\n", $x[0]);
		printf("\tPRN %d\n", $x[1]);
		printf("\tState 0x%x %s\n", $x[2], GPS::SiRF::Decoders::decode_sync_flags($x[2]));
		printf("\tBit Number %d\n", $x[3]);
		printf("\tMillisecond Number %d\n", $x[4]);
		printf("\tChip Number %d\n", $x[5]);
		printf("\tCode Phase %d\n", $x[6]);
		printf("\tCarrier Doppler %d\n", $x[7]);
		printf("\tReceiver Time Tag %d\n", $x[8]);
		printf("\tDelta Carrier %d\n", $x[9]);
		printf("\tSearch Count %d\n", $x[10]);
		printf("\tPower Bad Count %d\n", $x[21]);
		printf("\tPhase Bad Count %d\n", $x[22]);
		printf("\tAccumulation Time %d\n", $x[23]);
		printf("\tTrack Loop Time %d\n", $x[24]);
		@x = @x[11..20]; $a = sum(@x) / 10;
		printf("\tSNR %d %d %d %d %d %d %d %d %d %d (average %3.1f)\n", @x, $a);
	}
	return @rv;
}
