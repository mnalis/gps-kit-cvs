# $CSK: Lib.pm,v 1.16 2006/09/13 16:33:28 ckuethe Exp $

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

package GPS::SiRF::Lib;

use Time::HiRes qw( gettimeofday usleep time);
use GPS::Tools;

use Exporter;
@ISA = ('Exporter');     # Inherit from Exporter
@EXPORT = @EXPORT_OK = qw(sirf_packet_type sirf_packet_name sirf_setpacketinterval sirf_runquery sirf_cold_debug sirf_no_debug sirf_enable_tracker sirf_disable_tracker sirf_enable_sbas sirf_disable_tricklepower sirf_sync_serial);

return 1;

### sirf_packet_type - dig into the packet for the type
### input: a raw packet
### output: nothing
### return: the packet type
sub sirf_packet_type{
	return 0 if (is_invalid_sirf($_[0]));
	return ord(substr($_[0],4,1));
}

### sirf_packet_name - dig into the packet for the type
### input: a packet number
### output: nothing
### return: the packet name
sub sirf_packet_name{
	my $i = shift;
	my %m = ( 2 => "Navigation Solution [2]", 4 => "Measured Tracker Data [4]", 5 => "Raw Tracker Output (obsolete) [5]", 6 => "Version String [6]", 7 => "Clock Status [7]", 8 => "50Hz Data [8]", 9 => "CPU Utilization [9]", 10 => "Error [10]", 11 => "Command ACK [11]", 12 => "Command NAK [12]", 13 => "Visble List [13]", 14 => "Almanac Data [14]", 15 => "Ephemeris Data [15]", 17 => "Differential Corrections [17]", 18 => "OkToSend [18]", 27 => "DGPS Status [27]", 28 => "NavLib Measurement Data [28]", 29 => "NavLib DGPS Data [29]", 30 => "NavLib SV State Data [30]", 31 => "NavLib Initialization Data [31]", 41 => "Geodetic Navigation Data [41]", 50 => "SBAS Corrections [50]", 52 => "PPS Time [52]", 255 => "Debug [255]");
	return sprintf("Unknown [%d]", $i) unless ( defined($m{$i}) );
	return $m{$i};
}

### sirf_setpacketinterval - control and polling for adjustable rate packets
### input: a port descriptor, packet type, interval, and whether to poll now
### output: nothing
### return: nothing
sub sirf_setpacketinterval{
	my ($sp, $type, $interval, $send_now, undef) = @_;
	my $packet = "\xa0\xa2";

	return unless (defined($sp) && defined($type) && defined($interval) && defined($send_now));

	$send_now = 1 if ($send_now != 0);

	$interval = 0 if ($interval < 0);
	$interval = 255 if ($interval > 255);

	return if (($type < 0) || ($type > 127));

	my $str = "\xa6";
	$str .= pack("C C C N", $send_now, $type, $interval, 0);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	$eb += $sp->write($packet);
	usleep(1000);
}

### sirf_runquery - send a certain type of poll packet
### input: a port descriptor and packet type
### output: nothing
### return: nothing
sub sirf_runquery{
	my ($sp, $type, undef) = @_;
	my $packet = "\xa0\xa2";

	my $str = "";
	$str .= pack("C C", $type, 0);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	$eb += $sp->write($packet);
	usleep(1000);
}

### sirf_cold_debug - do a cold start with debugging
### input: a port descriptor
### output: nothing
### return: nothing
sub sirf_cold_debug{
	my ($sp, undef) = @_;
	my $packet = "\xa0\xa2";

	my $str = "";
	# warm reset, enable raw track data
	$str .= pack("  C     N  N  N  N  N  n  C   C",
			0x80, 0, 0, 0, 0, 0, 0, 12, 0xfe);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	$eb +=  $sp->write($packet);
	usleep(50000);
}

### sirf_no_debug - do a snap start without debugging
### input: a port descriptor
### output: nothing
### return: nothing
sub sirf_no_debug{
	my ($sp, undef) = @_;
	my $packet = "\xa0\xa2";

	my $str = "";
	# warm reset, enable raw track data
	$str .= pack("  C     N  N  N  N  N  n  C   C",
			0x80, 0, 0, 0, 0, 0, 0, 12, 0x00);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	$eb +=  $sp->write($packet);
	usleep(50000);
}

### sirf_enable_tracker - set the reset register to enable debug at restart
### input: a port descriptor
### output: nothing
### return: nothing
sub sirf_enable_tracker{
	my ($sp, undef) = @_;
	my $packet = "\xa0\xa2";

	my $str = "";
	# warm reset, enable raw track data
	$str .= pack("  C     N  N  N  N  N  n  C   C",
			0x80, 0, 0, 0, 0, 0, 0, 12, 0x32);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	$eb +=  $sp->write($packet);
	usleep(1000);
}

### sirf_disable_tracker - set the reset register to enable debug at restart
### input: a port descriptor
### output: nothing
### return: nothing
sub sirf_disable_tracker{
	my ($sp, undef) = @_;
	my $packet = "\xa0\xa2";

	my $str = "";
	# snap start or hot reset, enable raw track data
	$str .= pack("  C     N  N  N  N  N  n  C   C",
			0x80, 0, 0, 0, 0, 0, 0, 12, 0x00);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	$eb +=  $sp->write($packet);
	usleep(1000);
}

### sirf_enable_sbas - enable SBAS (WAAS, EGNOS, etc.)
### input: a port descriptor
### output: nothing
### return: nothing
sub sirf_enable_sbas{
	my ($sp, undef) = @_;
	my $packet = "\xa0\xa2";

	my $str = "";
	# Set DGPS to WAAS, (auto bitrate and frequency)
	$str .= pack("	C    C  N  C",
			133, 1, 0, 0);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";
	
	$eb += $sp->write($packet);
	usleep(1000);
}

### sirf_disable_tricklepower - disable the foofy powersaving features
### input: a port descriptor
### output: nothing
### return: nothing
sub sirf_disable_tricklepower{
	my ($sp, undef) = @_;
	my $packet = "\xa0\xa2";

	my $str = "";
	$str .= pack("	C    n  n  N",
			151, 0, 1000, 1000);
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";
	
	$eb += $sp->write($packet);
	usleep(1000);
}

### sirf_sync_serial - make the GPS and the software use the same settings
### input: a port descriptor, protocol ("SiRF" or "NMEA" - nocase) and speed
### output: nothing
### return: 1 if serial has been set OK, 0 if something went wrong
sub sirf_sync_serial {
	my %s = qw(4800 1 9600 1 19200 1 38400 1 57600 1 115200 1);
	my ($sp, $proto, $speed, undef) = @_;

	return 0 unless (defined($s{$speed}));
	$proto =~ tr/A-Z/a-z/; my $p = $proto;
	if ($proto eq "nmea"){
		$proto = 1;
	} elsif ($proto eq "sirf"){
		$proto = 0;
	} else {
		return 0;
	}

	my $npacket = "PSRF100,$proto,$speed,8,1,0";
	$npacket = '$' . $npacket . '*' . checksum_nmea($npacket) . "\r\n\r\n";

	my $packet = "\xa0\xa2";
	my $str = "\xa5";
	# set up serial port A, don't mess with any of the others
	# inproto, outproto, speed, data, stop, parity, reserved
	$str .= pack("C C C N C C C C C", 0, $proto, $proto, $speed, 8, 1, 0, 0, 0);
	$str .= pack("C C C N C C C C C", 255, 5, 5, 0, 0, 0, 0, 0, 0);
	$str .= pack("C C C N C C C C C", 255, 5, 5, 0, 0, 0, 0, 0, 0);
	$str .= pack("C C C N C C C C C", 255, 5, 5, 0, 0, 0, 0, 0, 0);
	
	$packet .= pack("n", length($str));
	$packet .= $str;
	$packet .= pack("n", checksum_sirf($str));
	$packet .= "\xb0\xb3";

	# just try kick the protocol over at our current operating speed
	print STDERR "nmea -> $p/$speed\n";
	$sp->write($npacket);
	usleep(32*(1000000/$speed)*length($npacket));

	print STDERR "sirf -> $p/$speed\n";
	$sp->write($packet);
	usleep(32*(1000000/$speed)*length($packet));

	# don't try set speed if we're already set to it
	#delete($s{$speed});

	foreach (sort {$b <=> $a } keys %s){
		$sp->baudrate($_);

		usleep(32*(1000000/$speed)*length($packet));
		print STDERR "nmea $_ -> $p/$speed\n";
		$sp->write($npacket);
		usleep(32*(1000000/$speed)*length($npacket));

		print STDERR "sirf $_ -> $p/$speed\n";
		$sp->write($packet);
		usleep(32*(1000000/$speed)*length($packet));
	}
	# return 0 unless ($speed == $sp->baudrate($speed));
	$sp->baudrate($speed);
	usleep(32*(1000000/$speed)*length($packet . $npacket));
	return 1;
}
