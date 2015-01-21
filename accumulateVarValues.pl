#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";

my $version = "v.3";

# v.25:
#    added lines to recognize whether variable has string or a number values
#
# KNOWN BUGs:
#
# - should add an option that allows users to specify what the initial
#   value of cases with empty cells should be (since what would be an 
#   appropriate value depends on what's being counted).
#
# BUG fixes
#
# v.24 (tiflo): value for uninitialized cells was 1, but since the 
# length counts usually count words PRECEDING a target word, the more
# appropriate init value is 0

my $initValue = 0;

printVersionHeader("accumulateValues $version");
if ($help) { printHelp("accumulateValues"); }
elsif ($corpus eq "" || $NUM_factornames < 1) { printAbort(); }
else {
    %cases = parseFactorHash();

    foreach $factor_name (@factornames) {
        %cases = createFactor($factor_name, %cases);

        # ID of variable in the database file (i.e. column)
        $fid = getFactorID($factor_name, %cases);

	$changes=0;
	$NAchanges=0;

	# is the the variable to be accumulated over a string? 
	# default is: no
	my $isString;
	my $confidenceThatItsString = 0;
        foreach $id (keys %cases) {
            if (($id eq getHeaderID()) or ($cases{$id}[$fid] eq emptyValue())) { 
		next; 
	    } elsif ($cases{$id}[$fid] !~ /^[0-9]$/) { 
		$confidenceThatItsString++; 
	    } else { $confidenceThatItsString--; }

	    if ($confidenceThatItsString > 5) {	
		$isString= 1; last; 
	    } elsif ($confidenceThatItsString < -5) { $isString= 0; last; } 
        }

	foreach $id (sort sortTGrep2ID keys %cases) {
	    next if ($id eq getHeaderID());
	    
	    $cases{$id}[$fid]= getNewValue($id,$oldid,$factor_name);
	    $oldid = $id;
	}
    }
    if ($default ne emptyValue()) { addDefault($factor_name, %cases) };
    writeFactorHash(%cases);            
    printLine("$changes changes made to $factor_name.");
    if ($NAchanges > 0 ) { print formatWarning("$NAchanges changes are are based on missing values."); }
} 
printFooter();



sub getNewValue {
    # assume sorted values!
    my ($id,$oldid,$factor_name) = @_;
    if ($oldid == 0) { return $cases{$id}[$fid]; } 
    elsif ($id eq $oldid) { return $cases{$oldid}[$fid]; } # shortcut
    
    $id =~ /^(\d+):(\d+)$/ || die "FATAL ERROR: Could not parse $id\n";	# determine item ID of item to process
    my $sid = $1;
    my $nid = $2;
    
    $oldid =~ /^(\d+):(\d+)$/ || die "FATAL ERROR: Could not parse $oldid\n";  
    my $osid = $1;
    my $onid = $2;

    if ($cases{$id}[$fid] eq emptyValue()) {
	$NAchanges++;
	$changes++;
	if ($isString) { $cases{$id}[$fid] = ""; }
	else { $cases{$id}[$fid] = $initValue; } 
	if ($warnings) { warn formatWarning("Setting missing value for ".$factor_name." at ".$id." to 0"); }
    }
    
    # relies on sorting!
    if ($sid != $osid) { return $cases{$id}[$fid]; }
    elsif ($nid > $onid) {
	$changes++;
	if ($warnings) { warn formatWarning("Value of $id increased by $cases{$oldid}[$fid]\n"); }
	if ($isString) { 
	    if ($cases{$oldid}[$fid] eq "") { return $cases{$id}[$fid]; } 
	    else { return $cases{$oldid}[$fid]." ".$cases{$id}[$fid]; }
	}
	else { return $cases{$id}[$fid] + $cases{$oldid}[$fid]; }
    }
    else { 
	warn formatWarning("Script relies on sorting, but sorting seems to have been compromised!", 3); 
	return -1;
    }
}
