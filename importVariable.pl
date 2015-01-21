#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v.51";

my $delim = getDelimiter();
my @fid;
my @args;
my $missingargs = 0;

# needs at least one file name, specified by --files 
# accepts either of:
#     --files f1,f2,..,fK      [assumes that the column to import from each file is column #1;
#                               column name defaults to file name without path]
#     --files f1,f2,..,fK --cols c1,c2,..,cK              [imports columns cJ from file fJ]
#     --files f1 --cols c1,c2,..,cK                       [imports columns c1 ... cK from file f1]
# for all options you can specify the columns:
#     --colnames cn1,cn2,..,cnK       [provides the new variable names; has to match number of columns]

if ($#cols == -1) { for ($i = 0; $i <= $#factorfiles; $i++) { $cols[$i] = 1; } }
if ($#colnames == -1) { 
    my $i = 0;
    foreach $f (@factorfiles) { 
	$file = substr($f, rindex($f, "/") + 1);
	$colnames[$i] = $file; 
	$i++;
    }
}
if ($NUM_factorfiles == 1 && $#cols > 0) { for ($i=0; $i <= $#colnames; $i++) { $factorfiles[$i] = $factorfiles[0]; } }

printVersionHeader("ImportVariable $version");
if ($help) { printHelp("importVariable"); }
elsif ($corpus eq "" || $NUM_factorfiles == 0 || $#cols != $#colnames) { printAbort(); }
else {
    my %cases = parseFactorHash();
    
    my $numwarnings = 0;
    for ($i=0; $i <= $#colnames; $i++) {	
	printLine("File: $factorfiles[$i]");
	%cases = createFactor($colnames[$i], %cases);
	$fid[$i] = getFactorID($colnames[$i], %cases);		# ID of variable in the output file (i.e. column)
	printLine("$i\tVariable name: $colnames[$i], variable ID: $fid[$i], Column-in-file: $cols[$i]");
	
	open(FILE, $factorfiles[$i]) || die "Couldn't open $factorfiles[$i]\n";
	while (<FILE>) {
	    chop($_);
	    my ($id, @inFactors) = split($delim, $_);
	    $id =~ s/^(\d+:\d+)(:00){0,1}/\1/g;              		# get's rid of excel-caused format mistakes

	    if (!$cases{$id}) {
		if ($warnings) { warn "\t\tWARNING: Illegal case ID: $id \t(item ignored)\n" };
		$numwarnings++;
# debugging:		print "$id\n";
	    }								#   currently processed.
	    else {
		if ($cases{$id}[$fid[$i]] ne emptyValue()) { 
		    if ($warnings && $overwrite) { 
			warn "\tWARNING: Full cell at Item ID $id\n";	# alarm if the cell is full
			warn "\t         As requested (-o), cell content ($cases{$id}[$fid[$i]]) will be overwritten.\n\n"; 
		    }
		    elsif ($warnings) { warn "\tWARNING: Full cell at Item ID $id. Value ($cases{$id}[$fid[$i]]) NOT overwritten.\n" };
		    $numwarnings++;
		}							
		if ($cases{$id}[$fid[$i]] eq emptyValue() || $overwrite) { $cases{$id}[$fid[$i]] = @inFactors[$cols[$i]-1]; }
# debugging:		print $cases{$id}[$fid[$i]]."\n";
	    }
	}
    }
    writeFactorHash(%cases);
}
printFooter();
