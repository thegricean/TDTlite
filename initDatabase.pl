#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v.67";

printVersionHeader("initDatabase $version");
if ($help) { printHelp("initDatabase"); }
elsif ($corpus eq "" || $NUM_factorfiles < 1) { printAbort(); }
else {
    print "Reading in case IDs ...\n";
    open(RC, $factorfiles[0]) || die "Couldn't open $FACTORFILE[0] ($!)\n";
    
    print "Creating new database ...\n";
    my $output = getDatabaseName();
    open (OUT, ">$output") || die "Couldn't open $output for output: $!\n";
    my %cases= createFactorHash();
    while (<RC>) {
	/^(\d+:\d+)\s*.*/ || die "\tFATAL ERROR: Couldn't parse ID in [$_]\n";
	$cases{$1}= my @row;
    }
    
    if ($largs > 0) {
	print "Reading in variables ...\n";
	my $factor_file = shift(@ARGV);
	my @FACTORS= getFactors("$factor_file");
	while (<@FACTORS>) {							# create all the new factor names
	    %cases = createFactor($_, %cases);
	    print "Added variable $_\n"; 
	    $fid= getFactorID($_, %cases);
	}
	print "\n\n";
    }
    my $num_of_factors= getNumOfFactors(%cases);
    print "New database has Item_ID plus $num_of_factors (number variables) columns\n";
    
    writeFactorHash(%cases);
}
printFooter();
