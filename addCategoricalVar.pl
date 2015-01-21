#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v1.01";

my $DATAFILE_EXTENSION = getDataFileExtension();

printVersionHeader("addCategoricalVar $version");
if ($help) { printHelp("addCategoricalVar"); }
elsif ($corpus eq "" || $NUM_factornames != 1) { printAbort(); }
else {
	my %cases = parseFactorHash();
	my $factor_name = $factornames[0];
	if ($overwrite) { %cases = createFactor($factor_name, %cases) };
	my $fid = getFactorID($factor_name,%cases);					# ID of variable in the output file (i.e. column)
	print "(Value, File)-pairs processed in the following order:\n";

	my @file_name;
	my @value;
	my $n = @ARGV; 

        # read in the level values and corresponding and file names
	for ($level=0; $level < ($n / 2); $level ++) {	
	    $value[$level] = shift(@ARGV);
	    if ($value[$level] eq ".") { $value[$level] = emptyValue(); }
	    $file_name[$level] = shift(@ARGV);
	    if ($file_name[$level] !~ /${DATAFILE_EXTENSION}$/) { $file_name[$level] = $file_name[$level].$DATAFILE_EXTENSION; }
	    print "$level\tLevel-value: $value[$level], Level-file: $file_name[$level]\n";
	}
	print "\n";
	
	my $count_values = 0;
	my $count_overrides = 0;

	for ($level=0; $level < @file_name; $level++) {
	    open(FILE, $file_name[$level]) || die "Couldn't open $file_name[$level]: $!\n";
	    my $count = 0;
	    
	    while (<FILE>) {
	    	/^(\d+:\d+)/ || die "Could not parse $_\n";			# determine item ID of item to process
    		my $id = $1;
		
    		if (!$cases{$id}) {
		    print "\t\tERROR: Illegal Item ID: $id!.  Panic!\n";	# die if there is no item ID in the input/
		    die;							#   output file corresponding to the ID  
   		}								#   currently processed.
	
		if (($cases{$id}[$fid] ne emptyValue()) && ($cases{$id}[$fid] ne $value[$level])) {
		    if ($warnings) {
			print "\t\t\tWARNING: Full cell overwritten at Item ID $id\n";	# alarm if the cell being written 
			print "\t\t\t\tOLD CONTENT: $cases{$id}[$fid]\n";		#   to is not empty
			print "\t\t\t\tNEW CONTENT: $value[$level]\n";
		    }
		    $count_overrides++;
		}							

		$cases{$id}[$fid] = $value[$level];
		$count++;
	    }
	    print "\t\tLevel $level: $count values of type '$value[$level]' were found.\n"; 
	    $count_values += $count;
	}
	if ($default ne emptyValue()) { addDefault($factor_name, %cases) };
	    
        writeFactorHash(%cases);
	print "A total of $count_values values were found and printed.\n";
	if ($count_overrides > 0) { print "$count_overrides of these values overrode already existing values (see -w for details).\n"; }
    }
printFooter();
