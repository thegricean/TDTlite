#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v1.1";

printVersionHeader("AddLengthVar $version");
if ($help) { printHelp("addLengthVar"); }
elsif ($corpus eq "" || $NUM_factornames < 1) { printAbort(); }
else {
    my %cases = parseFactorHash();

    for ($i=0; $i <= $#factornames; $i++) {
	my $factor_name = $factornames[$i];
	my $file_name = $factorfiles[$i];
	%cases = createFactor($factor_name, %cases);
	my $fid = getFactorID($factor_name,%cases);
       
	my $count_values = 0;
	my $count_cells = 0;
	my $old_id = "";
        print "Getting data for variable $factor_name from file: $file_name\n";
	open(FILE, $file_name) || die "FATAL ERROR: Couldn't open input file $file_name for variable $factor_name: $!\n";
	while (<FILE>) {
	    # allows empty IDs to be ignored (important if input pattern contains marked node 
	    # twice which causes it to be printed twice!)
	    if (!/^(\d+:\d+)$/) {
		# determine item ID of item to process        
		/^(\d+:\d+)\t(.*)/ || die "FATAL ERROR: Could not parse $_ in File: $file_name\n";
		my $id = $1;
		my $target = stripForWordCount($corpus, $2);
		
		if (!$cases{$id}) {
		    if ($verbose) {
			# die if there is no item ID in the input/output file                     
			# that corresponds to the the ID currently being processed                                          
			print "FATAL ERROR: Illegal Item ID: $id in File: $file_name. Panic!\n";
			die;
		    }
		    next;
		}
		
		my $wordcount = split(/\s+/, $target);
		if ($wordcount eq "") { $wordcount = 0; }
		if ($cases{$id}[$fid] ne emptyValue()) {
		    if ($warnings) {
			# alarm if the cell being written to is not empty
			warn "\t\t\tWARNING: Cell full. Value added at Item ID $id\n";
			warn "\t\t\t\tOLD CONTENT: ".$cases{$id}[$fid]."\n";
			warn "\t\t\t\tNEW CONTENT: ".($cases{$id}[$fid] + 1)."\n";
		    }
		    $cases{$id}[$fid] += $wordcount;
		}
		else {
		    $cases{$id}[$fid] = $wordcount;
		}
		$count_values++;
		if ($id ne $old_id){ 
		    $count_cells++;
		}
		$old_id = $id;
	    }
	}
        print "A total of $count_values values were found and printed into an estimated $count_cells new cells.\n\n";
    }
    if ($default ne emptyValue()) { addDefault($factor_name, %cases) };    
    writeFactorHash(%cases);
} 
printFooter();

