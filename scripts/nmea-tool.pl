#!/usr/bin/perl

# $CSK: nmea-tool.pl,v 1.12 2006/09/07 15:17:36 ckuethe Exp $

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

use strict;
#use warnings;
use Curses;
use GD;
use Device::SerialPort;

$| = 1;
# $SIG{'INT'} = $SIG{'HUP'} = $SIG{'TERM'} = \&bye;
my ($sp, $s, $v, $p, @x, $win, $d, $n, %o, $size);
my ($PORT, %C, $GSA, $RMC, %satinfo, @nmea, $im);

my $doplot = 1;
my $dolog = 1;

while (@ARGV){
	$doplot = 0 if ($ARGV[0] eq "-noplot");
	$dolog = 0 if ($ARGV[0] eq "-nolog");
	shift;
}

$size = 400;
$PORT = "/dev/cuaU0";

open(DEV, "<$PORT") || die "Cannot open $PORT: $!\n";

$sp = Device::SerialPort->new ($PORT) || die "Can't Open $PORT: $!";
$sp->baudrate(4800)	|| die "failed setting baudrate";
$sp->parity("none")	|| die "failed setting parity";
$sp->databits(8)	|| die "failed setting databits";
$sp->handshake("none")	|| die "failed setting handshake";

#open (DEBUG, ">>debug.log");
#select((select(DEBUG), $| = 1)[0]);

if ($dolog){
	open (NMEA, ">>nmea.log");
	select((select(NMEA), $| = 1)[0]);
}

select((select(STDOUT), $| = 1)[0]);

$win = new Curses;
$RMC = $GSA = $p = 0;

while(<DEV>){
	print NMEA $_ if ($dolog);
	$n = 8;
	chomp;
	next unless (/^\$(\w{5}),(.+)$/);
	($s,$v) = ($1, $2);

	$d = "\$${s},${v}";
	$d = substr($d,0,80); # so long nmea strings don't overflow display
	push (@nmea, $d);
	shift @nmea if (9 < scalar @nmea);

	# pretty displays...
	print_nmea(0,0);
	print_constellation(23,0);
	$win->refresh;

	eval {my $func = \&{"parse_$s"} ; &$func($v); } ;
	if ($p){
	$win->clear;

	# we just nuked the window so we need to redraw the nmea stuff
	print_nmea(0,0);

	#print satellite info
	print_satinfo(18, 0);

	#print constellation info
	print_constellation(23,0);

	#output a graphic...
	satplot() if ($doplot);

	#output and unset print flag
	$win->refresh;
	$RMC = $GSA = $p = 0;

	# clear out the old junk;
	%o = ();
	foreach (qw(cons pdop date time used ok)){ $o{$_} = $satinfo{$_}; }

	%satinfo = (); %satinfo = %o;
	}
}
###########################################################################
sub print_constellation{
	my ($y,$x) = (@_)[0,1];

	$win->move($y, $x);
	$win->clrtoeol();
	$win->move($y, $x);
	$win->addstr(
		sprintf("Tracking %d SV%s (%d usable)\tDOP: %3.3f\t%s %s UTC",
		$satinfo{'cons'}, ($satinfo{'cons'}==1)?"":"s", $satinfo{'ok'},
		$satinfo{'pdop'}, $satinfo{'date'}, $satinfo{'time'}));
	$win->move(23,79); # line 24, char 80
}

sub print_nmea{
	my ($y,$x) = (@_)[0,1];
	my $n;
	# raw nmea dump
	foreach ($n = 0; $n < 9; $n++){
		$win->move($n+$y,0);
		$win->clrtoeol();
		$win->move($n,0);
		$win->addstr($nmea[$n]);
	}
	$win->move(8+$y,0);
	$win->addstr("=" x 80);
}

sub print_satinfo{
	my ($y,$x) = (@_)[0,1];
	my ($i, $s, @k, @t, $X, $Y);

	($X,$Y) = ($x, $y);
	# draw the line of "="
	$win->move($y, $x);
	$win->addstr("=" x 80);

	$i = 0;

	@k = sort {$a <=> $b } split(/,/, $satinfo{'svn'});
	foreach (@k){
		@t = (split(/,/, $satinfo{$_}))[0,1,2];
		$t[0] += 0; $t[1] += 0; $t[2] += 0;
		$s = sprintf("SV:%-3d Ch: %-2d SNR: %02d", @t);

		$y = $Y + 1 + int($i/3);
		$x = 26 * ($i % 3);
		$win->addstr($y, $x, $s);

		$x-= 2;
		$win->addstr($y, $x, "|") if ($i % 3);
		$i++;
	}
	$satinfo{'used'} = @k;
}

sub parse_GPGSV{
	my @w = split(/[,\*]/ , $_[0]);
	my ($a, $b, $i, $svn, $el, $az, $snr, @r, @h);
	($a, $b) = (@w)[0,1];

	#print mode
	$p = 1 if (($a == $b) && $GSA && $RMC);

	# number of satellites above the horizon
	$satinfo{'cons'} = $w[2];

	for($i = 0; $i < ((scalar @w)/4 -1); $i++){
		($svn, $el, $az, $snr) = (@w)[(4*$i+3)..(4*$i+6)];
		$svn += 0; $snr += 0;
		#stash the signal characteristics
		if(defined($satinfo{$svn})){
			@r = split(/,/,$satinfo{$svn});
		}
		$r[0] = $svn;
		$r[2] = $snr;
		$r[3] = $el;
		$r[4] = $az;
		$satinfo{$svn} = join(",", @r);

		#mark this satellite as seen
		if(defined($satinfo{'svn'})){
			@h = split(/,/,$satinfo{'svn'});
		}
		push(@h, $svn);
		$satinfo{'svn'} = join(",",@h);
	}
}

sub parse_GPGSA{
	my @x = split(/[,\*]/ , $_[0]);
	my $channel = 1;
	my @r = ();

	$satinfo{'ok'} = 0;
	$satinfo{'pdop'} = (@x)[-4];
	@x =  (@x)[2..13];

	foreach ( @x ){
		if (defined($_) && $_){
		# $_ = svn, $i = channel
		$_ += 0;
		if ( defined($satinfo{$_}) ){
			@r = split(/,/, $satinfo{$_});
		}
		$r[0] = $_;
		$r[1] = $channel;
		$r[2] = 0 unless defined($r[2]);
		$satinfo{$_} = join(",", @r);
		$channel++;
		$satinfo{'ok'}++;
		}
	}
	$GSA = 1;
}

sub parse_GPRMC{
	my @x = split(/[,\*]/ , $_[0]);
	$satinfo{'time'} = (@x)[0];
	$satinfo{'date'} = (@x)[8];
	$satinfo{'time'} =~ s/(\d{2})(\d{2})(\d{2})(.*)/$1:$2:$3/
		if defined($satinfo{'time'});
	$satinfo{'date'} =~ s/(\d{2})(\d{2})(\d{2})/$1\/$2\/$3/
		if defined($satinfo{'date'});
	$RMC = 1;
}


sub satplot{
	$im = GD::Image->new($size + 1, $size + 1);
	my (@t);

	$C{'white'} = $im->colorAllocate(255,255,255);
	$C{'ltgray'} = $im->colorAllocate(191,191,191);
	$C{'mdgray'} = $im->colorAllocate(127,127,127);
	$C{'dkgray'} = $im->colorAllocate(63,63,63);
	$C{'black'} = $im->colorAllocate(0,0,0);
	$C{'red'} = $im->colorAllocate(255,0,0);
	$C{'green'} = $im->colorAllocate(0,255,0);
	$C{'blue'} = $im->colorAllocate(0,0,255);

	foreach (split(/,/, $satinfo{'svn'})){
		@t = (split(/,/, $satinfo{$_}))[0,3,4,2];
		$t[0] += 0; $t[1] += 0; $t[2] += 0; $t[3] += 0;
		splot($size, @t);
	}

	skyview($size);
	$im->string(gdTinyFont,10 + $size/2,$size - 10,
		scalar gmtime(). " [UTC]",$C{'black'});

	# and draw it to a file
	my $pngdata = $im->png;
	my $tm = time();
	open (F, ">skyview.${tm}.png") || die;
	binmode F;
	print F $pngdata;
	close F;
}

sub splot{
	my ($size, $sv, $el, $az, $snr, undef) = @_;
	my ($x, $y) = azel2xy($az, $el, $size);
	my $color = $C{'green'};
	$color = $C{'blue'} unless($el>10);
	$color = $C{'red'} unless($snr);
	
	my $s = "${sv}";
	$im->string(gdMediumBoldFont,$x+4,$y+4,$s,$color);
	$im->arc($x, $y, 8, 8, 0, 360, $color);
	$im->fill($x, $y, $color);
}

sub skyview{
	my ($size, undef) = @_;
	my ($a);

	# Draw the skyplot
	$a = 90; $a = $size * 0.95 * ($a/180);
	$im->arc($size/2,$size/2,2 * $a,2 * $a,0,360,$C{'black'});
	$a = 85; $a = $size * 0.95 * ($a/180);
	$im->arc($size/2,$size/2,2 * $a,2 * $a,0,360,$C{'dkgray'});
	$a = 45; $a = $size * 0.95 * ($a/180);
	$im->arc($size/2,$size/2,2 * $a,2 * $a,0,360,$C{'black'});

	$a = 75; $a = $size * 0.95 * ($a/180);
	$im->arc($size/2,$size/2,2 * $a,2 * $a,0,360,$C{'ltgray'});
	$a = 60; $a = $size * 0.95 * ($a/180);
	$im->arc($size/2,$size/2,2 * $a,2 * $a,0,360,$C{'ltgray'});
	$a = 30; $a = $size * 0.95 * ($a/180);
	$im->arc($size/2,$size/2,2 * $a,2 * $a,0,360,$C{'ltgray'});
	$a = 15; $a = $size * 0.95 * ($a/180);
	$im->arc($size/2,$size/2,2 * $a,2 * $a,0,360,$C{'ltgray'});

	$im->line($size/2, 2, $size/2, $size-2, $C{'black'});
	$im->line(2, $size/2, $size-2, $size/2, $C{'black'});
	return 1;
}

sub azel2xy{
	my ($az, $el, $size, undef) = @_;

	#rotate coords... 90deg W = 180dec trig
	$az += 90;

	#turn into radians
	$az = d2r($az);

	# determine length of radius
	my $r = $size * 0.5 * 0.95;
	   $r -= $r * ($el/90);

	# and convert length/azimuth to cartesian
	my $x = sprintf("%d", ($size * 0.5) + ($r * cos $az));
	my $y = sprintf("%d", ($size * 0.5) + ($r * sin $az));

	return ($x, $y);
}

sub d2r{
	my ($d, undef) = @_;
	my $pi = 3.14159265359;
	$d %= 360;
	return $pi * $d / 180;
}
