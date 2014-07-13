# $CSK: Decoder_013.pm,v 1.5 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_013;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_13);

return 1;

sub sirf_packet_13{
	my ($packet, $quiet, $tm, undef) = @_;
	my $n = ord(substr($packet,0,1));
	my @rv = ($n);
	$packet = substr($packet, 1);

	if (!$quiet){
		print "$tm Visble List [13]\n";
		printf("\tSatellites Visible: %d\n", $n);
	}

	for(my $i = 0; $i < $n; $i++){
		@x = unpack("C n n", substr($packet, $i*5, 5) );
		push (@rv, @x);
		printf("\tChannel %2d: PRN: %2d azimuth: %3d elevation: %2d\n", $i+1, $x[0], $x[1], $x[2]) unless ($quiet);
	}
	return @rv;
}
