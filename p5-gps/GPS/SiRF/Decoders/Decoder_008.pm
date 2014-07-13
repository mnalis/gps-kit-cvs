# $CSK: Decoder_008.pm,v 1.11 2006/09/07 15:23:03 ckuethe Exp $

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

package GPS::SiRF::Decoders::Decoder_008;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;
use GPS::SiRF::Decoders;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_8);

# SV => pgid
our %sf4map =	(57 => 1, 25 => 2, 26 => 3, 27 => 4, 28 => 5, 57 => 6, \
		 29 => 7, 30 => 8, 31 => 9, 32 => 10, 57 => 11, 62 => 12, \
		 52 => 12, 53 => 14, 54 => 15, 57 => 16, 55 => 17, 56 => 18, \
		 58 => 19, 59 => 20, 57 => 21, 60 => 22, 61 => 23, 62 => 24, \
		 63 => 25);

our %sf5map =	(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 7, \
		 8 => 7, 9 => 9, 10 => 10, 11 => 11, 12 => 12, 13 => 13, \
		 14 => 14, 15 => 15, 16 => 16, 17 => 17, 18 => 18, 19 => 19, \
		 20 => 20, 21 => 21, 22 => 22, 23 => 23, 24 => 24, 51 => 25);


return 1;

sub sirf_packet_8{
	my ($packet, $quiet, $tm, undef) = @_;
	my @x = unpack("C C N10", $packet);
	my ($i, $n, $p);
	$n = 1;

	# Quoth the SiRF Documentation:
	# Each Word in Message 8 is 32 bit wide and represents a 30 bit word
	# of the 50 BPS data stream. The LSB of each 30 bit word of the 50 bps
	# data stream is aligned to the LSB of a 32 bit Word in Msg 8.
	# Unfortunately, the polarity of the data is not guaranteed. Both
	# statements contain the same data:

	# Message 8 word: 11011101 00111111 11001101 11101111
	# 50 bps data:      100010 11000000 00110010 00010000

	# Quoth the SiRF Documentation:
 	# Data is logged in ICD-GPS-200C format (available from
	# www.navcen.uscg.mil). The 10 words together comprise a complete
	# subframe of navigation message data. Within the word, the 30 bits
	# of the navigation message word are right justified, complete with
	# 24 data bits and 6 parity bits. Any inversion of the data has been
	# removed. The 2 MSBs of the word contain parity bits 29 and 30 in
	# bits 31 and 30, respectively, from the previous navigation message
	# word.

	# CSK sez: That's conflicting! Apparently SiRF changed something in
	# their more recent firmware. Still, it can't hurt to correct for data
	# inversion, and verify the data format. In fact, it's necessary for
	# backward compatibility.


	$p = (($x[2] & 0x3fc00000) >> 22);
	if ($p == 0x8b) {
		; # no op - polarity is correct
	} elsif ($p == 0x74){
		# correct the inverted polarity
		for($i = 0; $i < 10; $i++){
			$x[$i+2] ^= 0xffffffff;
		}
	} else {
		# corrupt frame - no preamble
		return;
	}

	for($i = 0; $i < 10; $i++){
		#use only the 30 bit word
		$x[$i+2] &= 0x3fffffff;
		# then shift it 6 bits right to 
		$x[$i+2] = $x[$i+2] >> 6;
	}

	my @how = GPS::SiRF::Decoders::decode_how($x[3]);
	my $svid = (($x[4] & 0xff ) >> 2);
	my $pgid = ($how[1] == 4) ? $sf4map{$svid} : $sf5map{$svid};

	if (!$quiet){
		print "$tm 50Hz Data [8]\n";
		printf("\tSV ID %d ", $x[1]);
		printf("\tChannel %d\n", $x[0]);
		printf("\tHandover  Word:\n");
		printf("\t\tsubframe: %d\n", $how[1]);
		printf("\t\tanti-spoofing: %s\n", $how[2]?"yes":"no");
		printf("\t\talert: %s\n", $how[3]?"yes":"no");
		printf("\tsv id: %d\n", $svid);
		printf("\tpage id: %d\n", $pgid);
	}

	($how[1] == 5) && ($n = d8_sf5($quiet, @x));
	($how[1] == 4) && ($n = d8_sf4($quiet, @x));
#	($how[1] == 3) && ($n = d8_sf3($quiet, @x));
#	($how[1] == 2) && ($n = d8_sf2($quiet, @x));
#	($how[1] == 1) && ($n = d8_sf1($quiet, @x));

	if (!$quiet){
		if ($n){
			for(my $i = 0; $i < 8; $i++){
				printf("\tWord %d: 0x%08x\n", $i+1, $x[$i+4]);
			}
		}

	}
	return @x;
}

sub int2bin{
	return unpack("B32", pack("N", $_[0]));
}

sub d8_sf4{
	my ($quiet, @x) = @_;
	my @how = GPS::SiRF::Decoders::decode_how($x[3]);
	my $svid = (($x[4] & 0xff ) >> 2);
	my $pgid = $sf4map{$svid};

	if ($pgid == 18) {
		$gps_ctx{'alpha_0'} = ($x[4] >> 8) & 0xff;
		$gps_ctx{'alpha_0'} = int2signed($gps_ctx{'alpha_0'}, 1) / (2**30);

		$gps_ctx{'alpha_1'} = $x[4] & 0xff;
		$gps_ctx{'alpha_1'} = int2signed($gps_ctx{'alpha_1'}, 1) / (2**27);

		$gps_ctx{'alpha_2'} = ($x[5] >> 16) & 0xff;
		$gps_ctx{'alpha_2'} = int2signed($gps_ctx{'alpha_2'}, 1) / (2**24);

		$gps_ctx{'alpha_3'} = ($x[5] >> 8) & 0xff;
		$gps_ctx{'alpha_3'} = int2signed($gps_ctx{'alpha_3'}, 1) / (2**24);

		$gps_ctx{'beta_0'} = ($x[5] >> 0) & 0xff;
		$gps_ctx{'beta_0'} = int2signed($gps_ctx{'beta_0'}, 1) * (2**11);

		$gps_ctx{'beta_1'} = ($x[6] >> 16) & 0xff;
		$gps_ctx{'beta_1'} = int2signed($gps_ctx{'beta_1'}, 1) * (2**14);

		$gps_ctx{'beta_2'} = ($x[6] >> 8) & 0xff;
		$gps_ctx{'beta_2'} = int2signed($gps_ctx{'beta_2'}, 1) * (2**16);

		$gps_ctx{'beta_3'} = ($x[6] >> 0) & 0xff;
		$gps_ctx{'beta_3'} = int2signed($gps_ctx{'beta_3'}, 1) * (2**16);

		$gps_ctx{'A_1'} = $x[7] & 0x00ffffff;
		$gps_ctx{'A_1'} = int2signed($gps_ctx{'A_1'}, 3) / (2**50);

		$gps_ctx{'A_0'} = (($x[8] & 0x00ffffff) << 8) | (($x[9] >> 16) & 0xff);
		$gps_ctx{'A_0'} = int2signed($gps_ctx{'A_0'}, 4) / (2**30);

		$gps_ctx{'t_ot'} = (($x[9] >> 8) & 0xff) * (2**12);

		$gps_ctx{'wn_t'} = ($x[9] >> 0) & 0xff;

		$gps_ctx{'t_ls'} = ($x[10] >> 16) & 0xff;
		$gps_ctx{'t_ls'} = int2signed($gps_ctx{'t_ls'}, 1);

		$gps_ctx{'wn_lsf'} = ($x[10] >> 8) & 0xff;

		$gps_ctx{'dn'} = (($x[10] & 0xff)>> 0);

		$gps_ctx{'t_lsf'} = ($x[11] >> 16) & 0xff;
		$gps_ctx{'t_lsf'} = int2signed($gps_ctx{'t_lsf'}, 1);


		if (!$quiet){
			printf("\talpha_0: %f\n", $gps_ctx{'alpha_0'});
			printf("\talpha_1: %f\n", $gps_ctx{'alpha_1'});
			printf("\talpha_2: %f\n", $gps_ctx{'alpha_2'});
			printf("\talpha_3: %f\n", $gps_ctx{'alpha_3'});

			printf("\tbeta_0: %d\n", $gps_ctx{'beta_0'});
			printf("\tbeta_1: %d\n", $gps_ctx{'beta_1'});
			printf("\tbeta_2: %d\n", $gps_ctx{'beta_2'});
			printf("\tbeta_3: %d\n", $gps_ctx{'beta_3'});

			printf("\tA_0: %f\n", $gps_ctx{'A_0'});
			printf("\tA_1: %f\n", $gps_ctx{'A_1'});
			printf("\tt_ot: %d\n", $gps_ctx{'t_ot'});
			printf("\twn_t: %d\n", $gps_ctx{'wn_t'});
			printf("\tt_ls: %d\n", $gps_ctx{'t_ls'});
			printf("\twn_lsf: %d\n", $gps_ctx{'wn_lsf'});
			printf("\tdn: %d\n", $gps_ctx{'dn'});
			printf("\tt_lsf: %d\n", $gps_ctx{'t_lsf'});
		}
	}
	return 0;
}


sub d8_sf5{
	my ($quiet, @x) = @_;
	my @how = GPS::SiRF::Decoders::decode_how($x[3]);
	my $svid = (($x[4] & 0xff ) >> 2);
	my $pgid = $sf5map{$svid};

	if ($svid == 51){
		$gps_ctx{$svid}->{'t_oa'} = ($x[4] & 0x00ff00) >> 8;
		$gps_ctx{$svid}->{'wn_a'} = ($x[4] & 0xff0000) >> 16;
	} else {
		$gps_ctx{$svid}->{'e'} = $x[4] >> 8;
		$gps_ctx{$svid}->{'t_oa'} = $x[5] & 0xff;
		$gps_ctx{$svid}->{'sigma_i'} = $x[5] >> 8;
		$gps_ctx{$svid}->{'omega_dot'} = $x[6] & 0xffff;
		$gps_ctx{$svid}->{'health'} = ($x[6] >> 16) & 0x3f;
		$gps_ctx{$svid}->{'root_a'} = $x[7];
		$gps_ctx{$svid}->{'omega_0'} = $x[8];
		$gps_ctx{$svid}->{'m_0'} = $x[9];

		if (!$quiet){
			printf("\tsv %2d e: %d\n", $svid, $gps_ctx{$svid}->{'e'});
			printf("\tsv %2d t_oa: %d\n", $svid, $gps_ctx{$svid}->{'t_oa'});
			printf("\tsv %2d sigma_i: %d\n", $svid, $gps_ctx{$svid}->{'sigma_i'});
			printf("\tsv %2d omega_dot: %d\n", $svid, $gps_ctx{$svid}->{'omega_dot'});
			printf("\tsv %2d health: %s\n", $svid, d8_sf5_p25($gps_ctx{$svid}->{'health'}));
			printf("\tsv %2d root_a: %d\n", $svid, $gps_ctx{$svid}->{'root_a'});
			printf("\tsv %2d omega_0: %d\n", $svid, $gps_ctx{$svid}->{'omega_0'});
			printf("\tsv %2d m_0: %d\n", $svid, $gps_ctx{$svid}->{'m_0'});
		}
	}
	return 0;
}

sub d8_sf5_p25{
	my $x = $_[0];
	my @z;
	@z = ("All Signals OK", "All Signals Weak", "All Signals Dead",
		"All Signals Have No Data Modulation", "L1 P Signal Weak",
		"L1 P Signal Dead", "L1 P Signal Has No Data Modulation",
		"L2 P Signal Weak", "L2 P Signal Dead",
		"L2 P Signal Has No Data Modulation", "L1 C Signal Weak",
		"L1 C Signal Dead", "L1 C Signal Has No Data Modulation",
		"L2 C Signal Weak", "L2 C Signal Dead",
		"L2 C Signal Has No Data Modulation",
		"L1 & L2 P Signal Weak", "L1 & L2 P Signal Dead",
		"L1 & L2 P Signal Has No Data Modulation",
		"L1 & L2 C Signal Weak", "L1 & L2 C Signal Dead",
		"L1 & L2 C Signal Has No Data Modulation", "L1 Signal Weak",
		"L1 Signal Dead", "L1 Signal Has No Data Modulation",
		"L2 Signal Weak", "L2 Signal Dead",
		"L2 Signal Has No Data Modulation", "SV Is Temporarily Out",
		"SV Will Be Temporarily Out", "Spare", "More Than One Anomaly");

	return sprintf("Nav Data %s, %s", ($x & 0x20)? "Bad" : "OK", $z[($x & 0x1f)]);

}
	#Quoth ICD-GPS-200C:
	#p.74: subframe4, page 18, word3, bits 62..61 = data id
	#p.74: subframe4, page 18, word3, bits 68..63 = subframe id
	#p.74: subframe4, page 18, word9, bits 249..241 = deltaT(ls)
	#p.74: subframe4, page 18, word10, bits 279..271 = deltaT(lsf)
	#p.80: handover word, bits 22..20 = subframe ID
	#p.105: p18 = svid56

#	my $wnt = ($x[9] & 0x00ff0000) >> 16;
#	my $t0  = ($x[9] & 0x0000ff00) >> 8;
#	my $ls  = unpack("c", pack("C", ($x[10] & 0xff)));
#	my $lsf = unpack("c", pack("C", ($x[11] & 0xff)));
#	my $A0  = (($x[8] & 0x00ffffff) << 8) + (($x[9] & 0xff));
#	my $A1  = ($x[7] & 0xffffffff);
#	$A0 = unpack("f", pack("L", $A0)) / 2**30;
#	$A1 = unpack("f", pack("L", $A1)) / 2**50;

#	my $dT = $ls + $A0 + $A1* ($TE - $t0 * 2**12 + 604800*($WN - $wnt));
#	printf("\tCurrent Leap Seconds %d\n", $ls);
#	printf("\tUTC Ref Week Number %d\n", $WN);
#	printf("\tA0 (bias) %f\n", $A0);
#	printf("\tA1 (drift) %f s/s\n", $A1);
#	printf("\twnt %d\n", $wnt);
#	printf("\tt0 (ref time) %d\n", $t0);
#	printf("\tTE %d\n", $TE);
#	printf("\tdT %d\n", $dT);


