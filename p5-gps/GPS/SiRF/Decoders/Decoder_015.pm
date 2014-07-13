# $CSK: Decoder_015.pm,v 1.6 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_015;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_15);

return 1;

sub sirf_packet_15{
	my ($packet, $quiet, $tm, undef) = @_;
	my (@x, $i, $w, $sf, @rv);

	print "$tm Ephemeris Data [15]\n";
	$x[$i] = ord substr($packet, 0, 1); # svid

# subframe 1
	$i++; $x[$i] = unpack("n", substr($packet, 1 , 2)); # svid
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 4 , 3)); # w2, sf1 (how)
	print join(" ", GPS::SiRF::Decoders::decode_how($x[$i]), "\n");
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 7 , 3)); # w3, sf1
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 10, 3)); # w4, sf1
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 13, 3)); # w5, sf1
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 16, 3)); # w6, sf1
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 19, 3)); # w7, sf1
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 22, 3)); # w8, sf1
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 25, 3)); # w9, sf1
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 28, 3)); # w10, sf1

# subframe 2
	$i++; $x[$i] = unpack("n", substr($packet, 31, 2)); # svid
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 34, 3)); # w2, sf2 (how)
	print join(" ", GPS::SiRF::Decoders::decode_how($x[$i]), "\n");
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 36, 3)); # w3, sf2
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 39, 3)); # w4, sf2
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 42, 3)); # w5, sf2
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 45, 3)); # w6, sf2
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 48, 3)); # w7, sf2
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 51, 3)); # w8, sf2
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 54, 3)); # w9, sf2
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 57, 3)); # w10, sf2

# subframe 3
	$i++; $x[$i] = unpack("n", substr($packet, 61, 2)); # svid
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 64, 3)); # w2, sf3 (how)
	print join(" ", GPS::SiRF::Decoders::decode_how($x[$i]), "\n");
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 66, 3)); # w3, sf3
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 69, 3)); # w4, sf3
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 72, 3)); # w5, sf3
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 75, 3)); # w6, sf3
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 78, 3)); # w7, sf3
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 81, 3)); # w8, sf3
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 84, 3)); # w9, sf3
	$i++; $x[$i] = unpack("N", chr(0) . substr($packet, 87, 3)); # w10, sf3

	printf("PRN %d\t0x%08x 0x%08x 0x%08x 0x%08x\n", $x[1],  $x[2],  $x[3],  $x[4],  $x[5]);
	printf("\t0x%08x 0x%08x 0x%08x 0x%08x\n",              $x[6],  $x[7],  $x[8],  $x[9]);
	printf("PRN %d\t0x%08x 0x%08x 0x%08x 0x%08x\n", $x[11], $x[12], $x[13], $x[14], $x[15]);
	printf("\t0x%08x 0x%08x 0x%08x 0x%08x\n",              $x[16], $x[17], $x[18], $x[19]);
	printf("PRN %d\t0x%08x 0x%08x 0x%08x 0x%08x\n", $x[21], $x[22], $x[23], $x[24], $x[25]);
	printf("\t0x%08x 0x%08x 0x%08x 0x%08x\n",              $x[26], $x[27], $x[28], $x[29]);

	return(@x);
}
