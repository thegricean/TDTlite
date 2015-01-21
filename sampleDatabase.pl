#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";
require "resources.pl";

# sample n cases from larger database
# and write them into database_test.tab

my $n= shift(@ARGV); 
my $version = "v.1";

printVersionHeader("SampleDatabase $version");
if ($help) { printHelp("sampleDataBase"); }
elsif ($corpus eq "") { printAbort(); }
else {
    my %cases = parseFactorHash();

    my $t = 0;
    my %newcases;
    
    print "Sampling $n cases from the database.\n";
    $newcases{ getHeaderID() } = [ @{ $cases{ getHeaderID() } } ];
    foreach (keys %cases) {
	if ($_ eq getHeaderID()) { next };
	if ($t >= $n) { last };
	$t++;
	$newcases{$_} = [ @{ $cases{$_} } ]; 
    }

    writeFactorHashToFile($corpus."_sample.tab", %newcases);
}
printFooter();
