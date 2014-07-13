#!/usr/bin/perl

# $CSK$

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

#use warnings;
use strict;

use Device::SerialPort;
use Time::HiRes qw( gettimeofday );
use Time::Local;

# http://search.cpan.org/src/SREZIC/perl-GPS-0.14/NMEA/Handler.pm
# http://www.gpsinformation.org/dale/nmea.htm
# http://www.commlinx.com.au/NMEA_sentences.htm
# http://pcptpp030.psychologie.uni-regensburg.de/trafficresearch/NMEA0183/
# http://vancouver-webpages.com/peter/idx_nmeadoc.html

$SIG{'INT'} = $SIG{'HUP'} = $SIG{'TERM'} = \&bye;
my ($PORT, $sp, $s, $v, %m, %old);
my ($tm, @tm);

$PORT = "/dev/cuaU0";
$sp = Device::SerialPort->new ($PORT) || die "Can't Open $PORT: $!";
$sp->baudrate(4800)	|| die "failed setting baudrate";
$sp->parity("none")	|| die "failed setting parity";
$sp->databits(8)	|| die "failed setting databits";
$sp->handshake("none")	|| die "failed setting handshake";

open(DEV, "<$PORT") || die "Cannot open $PORT: $!\n";

$| = 1;
my $n = "";
while(<DEV>){
	$tm = sprintf("%02d%02d%02d.%03d", (gmtime())[2,1,0], ((gettimeofday())[1])/1000);
	next unless (/^\$(\w{5}),(.+)$/);
	$n .= $_;
	($s,$v) = ($1, $2);


	$@ = "";

	eval {my $func = \&{"parse_$s"} ; &$func($v); } ;
	print "Unhandled record type: $s\n" if ($@);

#	finish_record() if ($s eq "GPRMC");
}


sub bye{
	#do cleanup stuff here
	close DEV;
	undef $sp;
	die "Caught signal... exiting.\n"
}

sub finish_record{ 
	my (@k1, @k2, @k3, $k1, $k2, $k3, %h1, %h2, %h3);
	my %ignore = ('backtrack' => 1, 'error' => 1, 'satellites' => 0, 'bearing' => 1);

	system("clear");
#	print $n; $n = "";
	@k1 = sort keys %m;
	foreach $k1 (@k1){
		next if ($ignore{$k1});
		%h1 = %{$m{$k1}};
		@k2 = sort keys %h1;
		foreach $k2 (@k2){
			if (($k1 eq "satellites") && ($k2 =~ /\d{2}/)){
				%h2 = %{$h1{$k2}};
				@k3 = sort keys %h2;
				foreach $k3 (@k3){
					print "$k1.$k2.$k3 -> " . $h2{$k3} . "\n";
				}
			} else {
				print "$k1.$k2 -> " . $h1{$k2} . "\n";
			}
		}
	}

	%old = %m;
	print "-" x 30 . "\n";
	sleep 2;
 }

###########################################################################

sub parse_GPRTE{
#	print "GPRTE - " . $_[0] . "\n";
}

sub parse_GPGGA{ 
	(
	$m{'fixdata'}->{'time'},
	$m{'fixdata'}->{'latitude'},
	$m{'fixdata'}->{'lt_hemi'},
	$m{'fixdata'}->{'longitude'},
	$m{'fixdata'}->{'ln_hemi'},
	$m{'fixdata'}->{'quality'},
	$m{'fixdata'}->{'satellites'},
	$m{'fixdata'}->{'precision'},
	$m{'fixdata'}->{'ant_height'},
	undef,
	$m{'fixdata'}->{'geoid_height'},
	undef,
	$m{'fixdata'}->{'dgps_age'},
	$m{'fixdata'}->{'dgps_refid'},
	undef) = split(/[,\*]/ , $_[0]);
	$m{'fixdata'}->{'gtod'} = $tm;
}

sub parse_GPRMC{ 
	(
	$m{'pvt'}->{'time'},
	$m{'pvt'}->{'status'},
	$m{'pvt'}->{'latitude'},
	$m{'pvt'}->{'lt_hemi'},
	$m{'pvt'}->{'longitude'},
	$m{'pvt'}->{'ln_hemi'},
	$m{'pvt'}->{'speed'},
	$m{'pvt'}->{'course'},
	$m{'pvt'}->{'date'},
	$m{'pvt'}->{'magnetic'},
	$m{'pvt'}->{'mag_dir'},
	undef) = split(/[,\*]/ , $_[0]);
	$m{'pvt'}->{'gtod'} = $tm;
	# print "RMC: $_[0]\n";
}

sub parse_PGRME{
	(
	$m{'error'}->{'err_hor'},
	undef,
	$m{'error'}->{'err_ver'},
	undef,
	$m{'error'}->{'err_sph'},
	undef) = split(/[,\*]/ , $_[0]);
}

sub parse_PGRMZ{
	(
	$m{'altitude'}->{'altitude'},
	undef,
	$m{'altitude'}->{'fix'},
	undef) = split(/[,\*]/ , $_[0]);
}

sub parse_GPGLL{
	(
	$m{'position'}->{'latitude'},
	$m{'position'}->{'lt_hemi'},
	$m{'position'}->{'longitude'},
	$m{'position'}->{'ln_hemi'},
	$m{'position'}->{'time'},
	$m{'position'}->{'status'},
	undef) = split(/[,\*]/ , $_[0]);
	$m{'position'}->{'gtod'} = $tm;
}

sub parse_GPBOD{ 
	(
	$m{'bearing'}->{'true'},
	undef,
	$m{'bearing'}->{'magnetic'},
	undef,
	$m{'bearing'}->{'finish'},
	$m{'bearing'}->{'origin'},
	undef) = split(/[,\*]/ , $_[0]);
}

sub parse_GPRMB{
	(
	$m{'backtrack'}->{'status'},
	$m{'backtrack'}->{'error'},
	$m{'backtrack'}->{'turn_to'},
	$m{'backtrack'}->{'origin'},
	$m{'backtrack'}->{'dest'},
	$m{'backtrack'}->{'latitude'},
	$m{'backtrack'}->{'lt_hemi'},
	$m{'backtrack'}->{'longitude'},
	$m{'backtrack'}->{'ln_hemi'},
	$m{'backtrack'}->{'distance'},
	$m{'backtrack'}->{'bearing'},
	$m{'backtrack'}->{'velocity'},
	$m{'backtrack'}->{'arrival'},
	undef) = split(/[,\*]/ , $_[0]);
}

sub parse_GPGSV{
	my @w = split(/[,\*]/ , $_[0]);
	$m{'satellites'}->{'constellation'} = $w[2];

	my ($i, @x, $a, $b);
	for($i = 0; $i < ((scalar @w)/4 -1); $i++){
		@x = @w[(4*$i+3)..(4*$i+6)];
		$x[0] += 0; $x[1] += 0; $x[2] += 0; $x[3] += 0;
		if ($x[3]){
			$m{'satellites'}->{$x[0]}->{'elevation'} = $x[1];
			$m{'satellites'}->{$x[0]}->{'azimuth'} = $x[2];
			$m{'satellites'}->{$x[0]}->{'snr'} = $x[3];
			printf("GPGSV - satellite %d: elevation %d, azimuth %d, SNR %d\n", @x) if ($x[3] > 0);
		}
	}
}

sub parse_GPGSA{
	(
	$m{'active_sat'}->{'mode'},
	$m{'active_sat'}->{'fix'},

	$m{'active_sat'}->{"channel_01"},
	$m{'active_sat'}->{"channel_02"},
	$m{'active_sat'}->{"channel_03"},
	$m{'active_sat'}->{"channel_04"},
	$m{'active_sat'}->{"channel_05"},
	$m{'active_sat'}->{"channel_06"},
	$m{'active_sat'}->{"channel_07"},
	$m{'active_sat'}->{"channel_08"},
	$m{'active_sat'}->{"channel_09"},
	$m{'active_sat'}->{"channel_10"},
	$m{'active_sat'}->{"channel_11"},
	$m{'active_sat'}->{"channel_12"},

	$m{'active_sat'}->{'pdop'},
	$m{'active_sat'}->{'hdop'},
	$m{'active_sat'}->{'vdop'},
	undef) = split(/[,\*]/ , $_[0]);
	# print "GSA: $_[0]\n";
}
