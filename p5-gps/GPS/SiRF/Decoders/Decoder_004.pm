# $CSK: Decoder_004.pm,v 1.6 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_004;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_4);

return 1;

sub sirf_packet_4{
	my ($packet, $quiet, $tm, undef) = @_;
	my $a = " ";
	my @x = unpack("n N C", substr($packet,0,7));
	my @rv = @x;
	$packet = substr($packet, 7);

	if (!$quiet){
		print "$tm Measured Tracker Data [4]\n";
		printf ("\tGPS Week: %d\n", $x[0]);
		printf ("\tGPS TOW: %8.2f\n", $x[1]/100);
		printf ("\tChannels: %d\n", $x[2]);
	}

	for(my $i = 0; $i < 12; $i++){
		@x = unpack("CCCn C10", substr($packet, $i*15, 15) );
		push (@rv, @x);
		if ($x[3] && !$quiet){
			printf("\tCH. %2d PRN: %2d azimuth: %3.1f elevation: %3.1f\n", $i+1, $x[0], $x[1]*1.5, $x[2]/2);
			printf("\tCH. %2d status: 0x%x %s\n", $i+1, $x[3], GPS::SiRF::Decoders::decode_sync_flags($x[3]));
			@x = @x[4..13]; $a = sum(@x) / 10;
			printf("\tCH. %2d SNR: %d %d %d %d %d %d %d %d %d %d (average %3.1f)\n", $i+1, @x, $a);
		}
	}
	return @rv;
}
