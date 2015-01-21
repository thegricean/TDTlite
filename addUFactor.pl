#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v.18";

printVersionHeader("AddNITE-ID $version");
if ($help) { printHelp("addUFactor"); }
elsif ($corpus eq "" || $#factornames < 0) { printAbort(); }
else {
    my %cases = parseFactorHash();
    
    foreach $factor_name (@factornames) {
	%cases = createFactor($factor_name, %cases);
	my $fid = getFactorID($factor_name,%cases);	      # ID of variable in the output file (i.e. column)
	
	my $count_found = 0;
	foreach $file_name (@factorfiles) {
	    print "Getting data from file: $file_name\n\n";
	    
	    open(FILE, $file_name) || die "FATAL ERROR: Couldn't open $file_name: $!\n";
	    while (<FILE>) {
		# determine item ID of item to process
		/^(\d+:\d+)\t(.*)/ || die "FATAL ERROR: Could not parse $_ in File: $file_name\n";
		my $id = $1;
		my $target = parseNITEID($2);
		
		if (!$cases{$id}) {
                    if ($verbose) {
                        # die if there is no item ID in the input/output file                                                
                        # that corresponds to the the ID currently being processed                                                
                        print "FATAL ERROR: Illegal Item ID: $id in File: $file_name. Panic!\n";
                        die;
                    }
                    next;
		}
		
		if ($cases{$id}[$fid] ne emptyValue()) {
		    if ($warnings){
			# alarm if the cell being written to is empty
			warn "\t\t\tWARNING: Cell full. Value added/overridden (depending on +/-c option) at Item ID $id\n";
			warn "\t\t\t\tOLD CONTENT: $cases{$id}[$fid]\n";
		    }
		    
		    # override or append string (depending on +/-c option)
		    if ($overwrite && $target ne "") { $cases{$id}[$fid] = $target; }
		    else { $cases{$id}[$fid] .= " ".$target }; 
		    if ($warnings){
			warn "\t\t\t\tNEW CONTENT: $cases{$id}[$fid]\n";
		    }
		}
		else {					
		    $cases{$id}[$fid] = $target;
		}
		$count_found++;
	    }
	}
	printLine("A total of $count_found values were found and printed.");
    }
    writeFactorHash(%cases);
}
printFooter();
