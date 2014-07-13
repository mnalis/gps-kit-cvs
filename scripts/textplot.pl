#!/usr/bin/perl -s

# $CSK: textplot.pl,v 1.4 2006/09/07 15:17:36 ckuethe Exp $

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

#simple text output format parser

use Time::Local;
$lc = 0;
$v = 0;
$m = 5 unless (defined($m) && ($m >= 1));
while(<>){
	chomp;
	next unless (/^@(\d+)(.)(\d+)(.)(\d+).\d{3}.\d{5}.(\d+).(\d+).\d+$/);
	$f1 = $f2 = 1;

	$v = 1.0 * sqrt($6*$6 + $7*$7) / 10;
	$a = abs($lv - $v); $lv = $v;
	@pvt = ($1, $5, $3, $v, $a);
	$pvt[0] = $lc;
	$f1 = -1 if ($4 eq "W");
	$f2 = -1 if ($2 eq "S");

	# longitude (X)
	$pvt[1] =~ /(\d{3})(\d+)/;
	$pvt[1] = 0+$1 + ($2/1000)/60;

	# latitude (Y)
	$pvt[2] =~ /(\d{2})(\d+)/;
	$pvt[2] = 0+$1 + ($2/1000)/60;

	$pvt[1] = $f1 * sprintf("%9.5f", $pvt[1]);
	$pvt[2] = $f2 * sprintf("%9.5f", $pvt[2]);
	$pvt[3] = sprintf("%3.3f", $pvt[3]);
	$pvt[4] = sprintf("%3.3f", $pvt[4]);

	print $_ . "\n";
	print "@pvt\n" if (($lc % $m) == 0);
	$lc++;
}
print "@pvt\n";
