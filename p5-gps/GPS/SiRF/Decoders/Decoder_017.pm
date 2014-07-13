# $CSK$

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

package GPS::SiRF::Decoders::Decoder_017;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_17);

return 1;

#This decoder is based on http://longwave.bei.t-online.de/104.pdf
sub sirf_packet_17{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("n N*", $packet);

	if (!$quiet){
		print "$tm Differential Corrections [17]\n";
		printf("\tpacket length  %d\n", length($packet));
		printf("\tpacket payload %d\n", $x[0]);

		printf("\tHDR (01100110): %s\n", substr(int2bin($x[1]),0,8));
		printf("\tType: %d\n", ($x[1] >> 8 & 0x3f));
		printf("\tStation: %d\n", ($x[1] >> 14 & 0x3ff));

		printf("\tZ-Count: %d\n", ($x[2] & 0x1fff));
		printf("\tSequence: %d\n", ($x[2] >> 13 & 0x07));
		printf("\tLength: %d\n", ($x[2] >> 16 & 0x1f));
		printf("\tHealth: %s\n", d17_f2(($x[2] >> 21 & 0x07)));
	}
	return $packet;
}

sub int2bin{
	return sprintf("%s", unpack("B32", pack("N", $_[0])));
}

sub d17_f2{
	my $x = shift;
	$x = 7 unless defined $x;
	($x == 0) && return "UDRE scale 1.0 (0)";
	($x == 1) && return "UDRE scale 0.75 (1)";
	($x == 2) && return "UDRE scale 0.5 (2)";
	($x == 3) && return "UDRE scale 0.3 (3)";
	($x == 4) && return "UDRE scale 0.2 (4)";
	($x == 5) && return "UDRE scale 0.1 (5)";
	($x == 6) && return "Transmission not monitored (6)";
	return "Reference station not working (7)";
}
