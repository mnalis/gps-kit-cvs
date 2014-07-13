# $CSK: Decoder_225.pm,v 1.4 2006/09/18 22:56:43 ckuethe Exp $

# Copyright (c) 2005,2006 Chris Kuethe <ckuethe@ualberta.ca>
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

package GPS::SiRF::Decoders::Decoder_225;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_225);

return 1;

sub sirf_packet_225{
	my ($packet, $quiet, $tm, undef) = @_;
	my $a = " ";
	my @rv = unpack("C n n n N N N N n C n C C C C C C n C C", $packet);
	my @x = ();

	if (!$quiet){
		print "$tm Statistics Channel [225]\n";
		if ($rv[0] == 0){
			my $str;
			foreach (split(//, substr($packet,1))){
				$str .= chr(ord($_) ^ 0xff);
			}
			@rv = (0, $str);
		}elsif ($rv[0] != 6){
			printf ("can't decode type %d\n", $rv[0]);
			return @x;
		}
		print "@rv\n";
	}

	return @x if (($rv[0] != 0) && ($rv[0] != 6));
	return @rv;
}
