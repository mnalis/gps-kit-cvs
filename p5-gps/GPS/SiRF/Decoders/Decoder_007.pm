# $CSK: Decoder_007.pm,v 1.3 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_007;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_7);

return 1;

sub sirf_packet_7{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("n N C N N N", $packet);

	if (!$quiet){
		print "$tm Clock Status [7]\n";
		printf("\tGPS Week %d\n", $x[0]); $WN = $x[0] % 256;
		printf("\tGPS TOW %8.2f\n", $x[1]/100);
		printf("\tSVs %d\n", $x[2]);
		printf("\tClock Drift %dHz\n", $x[3]);
		printf("\tClock Bias %dns\n", $x[4]);
		printf("\tEstimated GPS Time %dms\n", $x[5]); $TE = $x[5]/1000;
	}
	return @x;
}
