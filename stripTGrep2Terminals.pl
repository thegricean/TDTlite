#!/usr/bin/perl

use lib $ENV{"TDTlite"};
require "format.pl";

my $file = $factorfiles[0];

if (!$file) {
    while (<>) {
	$line= stripForPrint($corpus, $_);
	if ($line =~ /.*[a-zA-Z].*/) { 
		print $line;
		print "\n";
	}
    }
} else {
    open(F1, $file) || die "Could not open file $file: $!\n";
    while (<F1>) {
	$line= stripForPrint($corpus, $_);
	if ($line =~ /.*[a-zA-Z].*/) { 
		print $line;
		print "\n";
	}
    }
}

