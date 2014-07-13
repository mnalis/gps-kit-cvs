# $CSK: Decoder_050.pm,v 1.4 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_050;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_50);
my ($WN, $TE);

return 1;

sub sirf_packet_50{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("C C C C d", $packet);

	if (!$quiet){
		print("$tm SBAS Corrections [50]\n");
		printf("\tSBAS PRN: %s\n", $x[0]?$x[0]:"Auto");
		printf("\tSBAS Mode: %s\n", $x[1]?"Integrity Only":"Test Mode Allowed");
		printf("\tDGPS Validity: %ds\n", $x[2]);
		printf("\tFlag Bits: 0x%02x\n", $x[3]);
		printf("\t\tTimeout    (0x01): %s\n", ($x[3] & 0x01)? "Default" : "User");
		printf("\t\tHealth     (0x02): %s\n", ($x[3] & 0x02)? "Set" : "Unset");
		printf("\t\tCorrection (0x04): %s\n", ($x[3] & 0x04)? "Set" : "Unset");
		printf("\t\tSBAS PRN   (0x08): %s\n", ($x[3] & 0x08)? "Default" : "User");
	}
	return @x;
}
