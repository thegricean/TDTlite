#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v.2";

printVersionHeader("CountValuesPerLevel $version");
if ($help) { printHelp("CountValuesPerLevel"); }
elsif ($corpus eq "" || $factor_name eq "") { printAbort(); }
else {
	%cases = parseFactorHash();

	for ($i=0; $i <= $#factornames; $i++) {
	    # ID of variable in the output file (i.e. column)
	    my $fid = getFactorID($factornames[$i], %cases);	
	    
	    my $newfactor_name = "LevelCount_".$factornames[$i];
	    %cases = createFactor($newfactor_name, %cases);
	    my $new_fid = getFactorID($newfactor_name, %cases);
	    
	    my %newvalue;	
	    
	    foreach $id (sort keys %cases) {
		next if ($id eq getHeaderID());
		$newvalue{$cases{$id}[$fid]}++;
	    }
	    foreach $id (sort keys %cases) {
		next if ($id eq getHeaderID());
		$cases{$id}[$new_fid] = $newvalue{$cases{$id}[$fid]};
	    }
	    
	    @k =  keys %newvalue;
	    $levels = $#k + 1;
	    
	    print "\nCounted $levels distinct levels for variable ".$factornames[$i].".\n";
	}
	writeFactorHash(%cases);
} 
printFooter();
