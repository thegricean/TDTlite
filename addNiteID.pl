#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v.3";

printVersionHeader("AddNITE-ID $version");
if ($help) { printHelp("addNiteID"); }
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
            if (!/^(\d+:\d+)$/) {
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
