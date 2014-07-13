# $CSK: Decoder_014.pm,v 1.5 2006/09/07 15:23:49 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_014;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_14);

return 1;

sub sirf_packet_14{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("C n n12 n", $packet);

	if (!$quiet){
		print "$tm Almanac Data [14]\n";
		printf("\tPRN %d\n", $x[0]);
		printf("\tAlmanac Week: %d\n", $x[1] >> 6);
		printf("\tAlmanac Status: %svalid\n", ($x[1] & 0x3f)? "": "in");
		printf("\tAlmanac Data %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x\n", @x[2..13]);
		printf("\tPage Checksum %04x\n", $x[14]);
	}
	return @x;
}
