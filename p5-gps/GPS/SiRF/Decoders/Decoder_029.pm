# $CSK: Decoder_029.pm,v 1.4 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_029;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_29);

return 1;

sub sirf_packet_29{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("n n C N N N N N", $packet);

	if (!$quiet){
		print("$tm NavLib DGPS Data [29]\n");
		printf("\tPRN %d\n", $x[0]);
		printf("\tIssue of Data %d\n", $x[1]);
		printf("\tSource %d (%s)\n", $x[2],
			("None", "SBAS", "External Beacon", "Internal Beacon", "Fixed Correction")[$x[2]]);
		printf("\tPseudorange Correction %dm\n", $x[3]);
		printf("\tPseudorange Rate Correction %dm/s\n", $x[4]);
		printf("\tCorrection Age %ds\n", $x[5]);
		printf("\tReserved 1 0x%08x\n", $x[6]);
		printf("\tReserved 2 0x%08x\n", $x[7]);
	}
	return @x;
}
