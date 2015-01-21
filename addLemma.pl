#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";
require "resources.pl";

my $version = "v.23";

printVersionHeader("AddLemma $version");
if ($help) { printHelp("addLemma"); }
elsif ($corpus eq "") { printAbort(); }
else {
    my %cases = parseFactorHash();
    my %lemmas = getCELEXlemmas(@restrictors);
    
    # extraction lemma-information for each factor_name given
    foreach $factor_name (@factornames) {
	# name of new variable for lemma
	my $lemmafactor_name = $factor_name . "_lemma";
	# ID of variable in the output file (i.e. column)
	my $FID = getFactorID($factor_name, %cases);
	print "Variable ID for variable '$factor_name': $FID\n\n";
	
	%cases = createFactor($lemmafactor_name, %cases);
	my $lemmaFID = getFactorID($lemmafactor_name, %cases);
	
	my $count_nolemma = 0;
	foreach $id (keys %cases) {
	    if ($id ne getHeaderID()) {
		$cases{$id}[$lemmaFID] = "";
		my (@words)= split(/\s/,$cases{$id}[$FID]);
		foreach $word (@words) {
		    if ($lemmas{$word} ne "") { $cases{$id}[$lemmaFID] .= $lemmas{$word}." "; }
		    else {
			$count_nolemma++;
			$cases{$id}[$lemmaFID] .= "XXX "; 
		    }
		}
		$cases{$id}[$lemmaFID] =~ s/\s$//g;
		# remove X-mark if it's the only content (i.e. make cases NA).
		$cases{$id}[$lemmaFID] =~ s/^(XXX)+$//g;
	    }
	}
	if ($count_nolemma > 0) { printLine("No lemma information was found for $count_nolemma cases. Cells marked by XXX (if there were several words in each cell to lemmatize) or empty (if each cell contained only one word).") };
    }
    writeFactorHash(%cases);
}
printFooter();



