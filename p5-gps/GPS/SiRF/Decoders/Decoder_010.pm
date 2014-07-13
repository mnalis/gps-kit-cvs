# $CSK: Decoder_010.pm,v 1.4 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_010;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_10);

return 1;

sub sirf_packet_10{
	my ($packet, $quiet, $tm, undef) = @_;
	my $msg;
	my @x = unpack("n n", $packet);

	SWITCH: {
	( $x[0] == 2 ) && do { 
		@x = unpack("n n N N", $packet);
		$msg = "satellite $x[2] subframe $x[3] failed parity check";
		};
	( $x[0] == 9 ) && do { 
		@x = unpack("n n N", $packet);
		$msg = "Failed to obtain a position for acquired satellite ID $x[2]";
		};
	( $x[0] == 10 ) && do { 
		@x = unpack("n n N", $packet);
		$msg = "Conversion of Nav Pseudo Range to Time of Week for tracker exceeds limits.";
		};
	( $x[0] == 11 ) && do { 
		@x = unpack("n n N", $packet);
		$msg = "Convert pseudo range rate to doppler frequency exceeds limit.";
		};
	( $x[0] == 12 ) && do { 
		@x = unpack("n n N N", $packet);
		$msg = "Satellite $x[2]'s ephemeris age has exceeded 2 hours ($x[3] > 7200).";
		};
	( $x[0] == 13 ) && do { 
		@x = unpack("n n N N N", $packet);
		$msg = "SRAM position is bad during a cold start. ($x[2] / $x[3] / $x[4])";
		};
#	( $x[0] == X ) && do { 
#		@x = unpack("n n N N", $packet);
#		$msg = "woof";
#		};
	( $x[0] == 0x1001 ) && do { 
		@x = unpack("n n N*", $packet);
		$msg = "VCO lost lock indicator.";
		};
	( $x[0] == 0x1003 ) && do { 
		@x = unpack("n n N*", $packet);
		$msg = "Nav detect false acquisition, reset receiver by calling NavForceReset routine.";
		};
	( $x[0] == 0x1008 ) && do { 
		@x = unpack("n n N*", $packet);
		$msg = "Failed SRAM checksum during startup.";
		};
	( $x[0] == 0x1009 ) && do { 
		@x = unpack("n n N N", $packet);
		$msg = "Failed RTC SRAM checksum during startup."
		};
	( $x[0] == 0x100a ) && do { 
		@x = unpack("n n N N", $packet);
		$msg = "Failed battery-backing position because of ECEF velocity sum was greater than equal to 3600.";
		};
	( $x[0] == 0x100b ) && do { 
		@x = unpack("n n N N", $packet);
		$msg = "Failed battery-backing position because current navigation mode is not KFNav and not LSQFix."
		};
	( $x[0] == 0x2001 ) && do { 
		@x = unpack("n n N", $packet);
		$msg = "Buffer allocation error occurred. WTF!";
		};
	( $x[0] == 0x2002 ) && do { 
		@x = unpack("n n N N", $packet);
		$msg = "PROCESS_1SEC task was unable to complete upon entry. Overruns are occurring.";
		};
	( $x[0] == 0x2003 ) && do { 
		@x = unpack("n n N", $packet);
		$msg = "Failure of hardware memory test. WTF!";
		};

	# default goes here
	} # End of SWITCH

	if (!$quiet){
		print "$tm Error [10]\n";
		printf("\tType: %d\tCount: %d\n\tMessage: %s\n", $x[0], $x[1], $msg);
	}
	return @x;
}
