# $CSK: Lib.pm,v 1.8 2006/09/07 15:22:54 ckuethe Exp $

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

package GPS::Garmin::Lib;
use strict;
no strict "subs";
use warnings;

BEGIN {
	use constant {
	PID_ACK_BYTE => 6,
	PID_NAK_BYTE => 21,
	PID_PROTOCOL_ARRAY => 253,
	PID_PRODUCT_RQST => 254,
	PID_PRODUCT_DATA => 255,

	PID_COMMAND_DATA => 10,
	PID_XFER_CMPLT => 12,
	PID_DATE_TIME_DATA => 14,
	PID_POSITION_DATA => 17,
	PID_PRX_WPT_DATA => 19,
	PID_RECORDS => 27,
	PID_RTE_HDR => 29,
	PID_RTE_WPT_DATA => 30,
	PID_ALMANAC_DATA => 31,
	PID_TRACK_DATA => 34,
	PID_WPT_DATA => 35,
	PID_PVT_DATA => 51,
	PID_RTE_LINK_DATA => 98,
	PID_TRACK_HDR_DATA => 99,
	PID_FLIGHTBOOK_RECORD => 139,

	PID_LAP => 149,
	PID_ALMANAC_DATA_2 => 4,
	PID_COMMAND_DATA_2 => 11,
	PID_DATE_TIME_DATA_2 => 20,
	PID_POSITION_DATA_2 => 24,
	PID_PRX_WPT_DATA_2 => 27,
	PID_RECORDS_2 => 35,
	PID_RTE_HDR_2 => 37,
	PID_WPT_DATA_2 => 43,

	PID_UNDOC_EVENT => 13,
	PID_UNDOC_PVT => 20,
	PID_UNDOC_POSITION_ERR => 23,
	PID_UNDOC_SATELLITE => 22,
	PID_UNDOC_SATELLITE_STATUS => 26,
	PID_UNDOC_ASYNC => 28,
	PID_UNDOC_VERSION => 32,
	PID_UNDOC_SATELLITE_SEL => 42,
	PID_UNDOC_SATELLITE_MSG => 54,
	PID_UNDOC_TIME => 55,
	PID_UNDOC_SATELLITE_MSG_2 => 56
};


	use Time::HiRes qw(gettimeofday usleep time);
	use Exporter;
	our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	@ISA = qw(Exporter);     # Inherit from Exporter

	@EXPORT = @EXPORT_OK = qw(unescape escape packet_build packet_type packet_read packet_ack packet_nak pid2txt PID_ACK_BYTE PID_NAK_BYTE PID_PROTOCOL_ARRAY PID_PRODUCT_DATA PID_PRODUCT_RQST PID_COMMAND_DATA PID_XFER_CMPLT PID_DATE_TIME_DATA PID_POSITION_DATA PID_PRX_WPT_DATA PID_RECORDS PID_RTE_HDR PID_RTE_WPT_DATA PID_ALMANAC_DATA PID_TRACK_DATA PID_WPT_DATA PID_PVT_DATA PID_RTE_LINK_DATA PID_TRACK_HDR_DATA PID_FLIGHTBOOK_RECORD PID_LAP PID_ALMANAC_DATA_2 PID_COMMAND_DATA_2 PID_DATE_TIME_DATA_2 PID_POSITION_DATA_2 PID_PRX_WPT_DATA_2 PID_RECORDS_2 PID_RTE_HDR_2 PID_WPT_DATA_2 PID_UNDOC_EVENT PID_UNDOC_PVT PID_UNDOC_POSITION_ERR PID_UNDOC_SATELLITE PID_UNDOC_SATELLITE_STATUS PID_UNDOC_ASYNC PID_UNDOC_VERSION PID_UNDOC_SATELLITE_SEL PID_UNDOC_SATELLITE_MSG PID_UNDOC_TIME PID_UNDOC_SATELLITE_MSG_2) ;
}
our @EXPORT_OK;

return 1;

### packet_type - extracts the packet's numeric type
### input: an unescaped packet
### output: nothing
### return: a numeric packet type
sub packet_type{
	my ($packet, undef) = @_;
	my ($p_type, $r);

	return 0 unless ($packet =~ /\x10(.)(.+?)(.)\x10\x03/ism);
	$p_type = ord($1);
	return ($p_type);
}

### packet_build - generates a properly formatted packet for transmission
### input: 2 elements: type in decimal and a string with the body
### output: none
### return: a properly formatted and escaped packet ready for the wire
sub packet_build{
	my ($type, $body, undef) = @_;
	my $len = length($body);

	my $pkt = "\x10";
	$type = chr($type);
	$len = chr($len);
	my $c = pack("C", checksum_garmin($type . $len . $body));
	$pkt .= $type . escape($len . $body . $c) . "\x10\x03";
	return $pkt;
}

### packet_read - read a packet off the wire
### input: a serial port descriptor
### output: nothing
### return: a raw packet hot off the wire
sub packet_read{
	my ($sp, undef) = @_;
	my ($rl, $b, $msg);

	$msg = "";
	do {
		($rl, $b) = $sp->read(1);
		$msg .= $b;
	} until ($msg =~ /(\x10.+?\x10\x03)/);

	return $msg;
}

### packet_ack - try to acknowledge a packet
### input: the packet to be acknowledged
### output: nothing
### return: nothing
sub packet_ack{
	my ($packet, undef) = @_;

	my $type = packet_type($packet);
	my @p = (PID_ACK_BYTE, chr($type));
	$packet = packet_build(@p);
	$sp->write($packet);
#	Garmin::Decoders::packet_parse($packet);
}

### packet_ack - try to negatively acknowledge a packet
### input: the packet to be acknowledged
### output: nothing
### return: nothing
sub packet_nak{
	my ($packet, undef) = @_;

	my $type = packet_type($packet);
	my @p = (PID_NAK_BYTE, chr($type));
	$packet = packet_build(@p);
	$sp->write($packet);
#	Garmin::Decoders::packet_parse($packet);
}

### pid2txt - turns a packet's number into a name
### input: a numeric packet type
### output: nothing
### return: a string containing the packet's description
sub pid2txt{
	my ($p_type, undef) = @_;
	
	my %h = (
	#link protocol 2 - aviation products
	GPS::Garmin::Lib::PID_ALMANAC_DATA_2 => "Almanac Data",
	GPS::Garmin::Lib::PID_COMMAND_DATA_2 => "Command Data",
	GPS::Garmin::Lib::PID_DATE_TIME_DATA_2 => "Date/Time Data",
	GPS::Garmin::Lib::PID_POSITION_DATA_2 => "Position Data",
	GPS::Garmin::Lib::PID_PRX_WPT_DATA_2 => "Proximity Waypoint Data",
	GPS::Garmin::Lib::PID_RECORDS_2 => "Records",
	GPS::Garmin::Lib::PID_RTE_HDR_2 => "Route Header",
	GPS::Garmin::Lib::PID_WPT_DATA_2 => "Waypoint Data",

	#link protocol 1 - most products
	GPS::Garmin::Lib::PID_COMMAND_DATA => "Command Data",
	GPS::Garmin::Lib::PID_XFER_CMPLT => "Transfer Complete",
	GPS::Garmin::Lib::PID_DATA_TIME_DATA => "Date/Time Data",
	GPS::Garmin::Lib::PID_POSITION_DATA => "Position Data",
	GPS::Garmin::Lib::PID_PRX_WPT_DATA => "Proximity Waypoint Data",
	GPS::Garmin::Lib::PID_RECORDS => "Records",
	GPS::Garmin::Lib::PID_RTE_HDR => "Route Header",
	GPS::Garmin::Lib::PID_RTE_WPT_DATA => "Route Waypoint Data",
	GPS::Garmin::Lib::PID_ALMANAC_DATA => "Almanac Data",
	GPS::Garmin::Lib::PID_TRACK_DATA => "Track Data",
	GPS::Garmin::Lib::PID_WPT_DATA => "Waypoint Data",
	GPS::Garmin::Lib::PID_PVT_DATA => "PVT Data",			# 0x33
	GPS::Garmin::Lib::PID_RTE_LINK_DATA => "Route Link Data",
	GPS::Garmin::Lib::PID_TRACK_HDR_DATA => "Track Header",
	GPS::Garmin::Lib::PID_FLIGHTBOOK_RECORD => "Flightbook Record",
	GPS::Garmin::Lib::PID_LAP => "Lap Record",

	#link protocol - undocumented or obsolete commands
	GPS::Garmin::Lib::PID_UNDOC_EVENT => "Undoc Event", # 0x0d
	GPS::Garmin::Lib::PID_UNDOC_PVT => "Undoc PVT", # 0x14
	GPS::Garmin::Lib::PID_UNDOC_SATELLITE => "Undoc Satellite", # 0x16
	GPS::Garmin::Lib::PID_UNDOC_POSITION_ERR => "Position Error", # 0x17
	GPS::Garmin::Lib::PID_UNDOC_SATELLITE_STATUS => "Satellite Status", # 0x1a
	GPS::Garmin::Lib::PID_UNDOC_ASYNC => "Undoc Async",
	GPS::Garmin::Lib::PID_UNDOC_VERSION => "Software Version",
	GPS::Garmin::Lib::PID_UNDOC_SATELLITE_SEL => "Satellite Select",
	GPS::Garmin::Lib::PID_UNDOC_SATELLITE_MSG => "Satellite Message", # 0x36
	GPS::Garmin::Lib::PID_UNDOC_TIME => "Time etc?", # 0x37
	GPS::Garmin::Lib::PID_UNDOC_SATELLITE_MSG_2 => "Satellite Message", # 0x38

	#basic protocol
	GPS::Garmin::Lib::PID_ACK_BYTE => "ACK",
	GPS::Garmin::Lib::PID_NAK_BYTE => "NAK",
	GPS::Garmin::Lib::PID_PROTOCOL_RQST => "Protocol Array",
	GPS::Garmin::Lib::PID_PRODUCT_RQST => "Product Request",
	GPS::Garmin::Lib::PID_PRODUCT_DATA => "Product ID");
	return (($h{$p_type} || "unknown") . " <$p_type>");

}

### escape - remove the byte stuffing
### input: a string suitable for byte stuffing
### output: nothing
### return: a byte stuffed string
sub escape{
	my $m = $_[0];
	$m =~ s/\x10/\x10\x10/g;
	return $m;
}

### unescape - remove the byte stuffing
### input: the raw string from $serialport->read()
### output: nothing
### return: a unescaped packet
sub unescape{
	my $m = $_[0];
	my @p = ();
	if( $m =~ /(\x10.)(.+?)(\x10\x03)(.*)/gism){
		@p = ($1, $2, $3);
		$p[1] =~ s/\x10\x10/\x10/g;
		return join('',@p);
	}
	return "invalid";
}

