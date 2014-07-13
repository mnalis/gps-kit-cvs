# $CSK: Decoder_052.pm,v 1.3 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_052;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_52);

return 1;

sub sirf_packet_52{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("C C C C C n n N C N", $packet);

	if (!$quiet){
		print("$tm PPS Time [52]\n");
		printf("\tTime: %04d/%02d/%02d %02d:%02d:%02d\n", (@x)[5,4,3,0,1,2]);
		printf("\tUTC Offset: %d.%09ds\n", $x[6], $x[7]);
		printf("\tStatus: %s\n", d52_f8($x[8]));
	}
	return @x;
}

sub d52_f8{
        my $x = shift;
        my $a = sprintf("Time %svalid", ($x & 0x0001) ? "" : "in");
        my $b = sprintf("%s timescale", ($x & 0x0002) ? "UTC" : "GPS");
        my $c = sprintf("%s IONO/UTS Data", ($x & 0x0004) ? "Current" : "Outdated");
        return join(", ", $a, $b, $c);
}

