# $CSK: Decoder_027.pm,v 1.8 2006/09/19 21:39:50 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_027;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_27);

return 1;

sub sirf_packet_27{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = ();
	@x = unpack("C*", substr($packet,0,13));

	for(my $i = 0; $i < 12; $i++){
		push(@x, unpack("Cs",substr($packet,15+$i*3,3)));
	}

	#channel 0 = x[1,14,15]
	#channel 1 = x[2,16,17]
	if (!$quiet){
		print("$tm DGPS Status [27]\n");
		printf("\tSource: %s\n", d27_f1($x[0]));
# XXX This assumes we're always using SBAS, which might not be true.
		for (my $i = 0; $i<12; $i++){
			printf("\tPRN: %3d, age: %3ds, correction %3dcm\n", $x[2*$i+15], $x[$i+1], $x[2*$i+14]);
		}
	}
	return (@x);
}

sub d27_f1{
        my @a = ("None", "SBAS", "Serial", "Beacon", "Software");
        my $x = $_[0];
           $x = (defined($a[$x])) ? $a[$x] : "Unknown";
        return sprintf("%s (%d)", $x, $_[0]);
}

