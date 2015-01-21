#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";
require "resources.pl";

my $version = "v.34";

my $larg = @ARGV;							# number of remaining arguments
my %lemmas;

printVersionHeader("AddConditionalProbability $version");
if ($help) { printHelp("addConditionalProbability"); }
elsif ($corpus eq "" || $#factornames < 0) { printAbort(); }
else {
    my %cases = parseFactorHash();
    if ($OPT_lemmatize) { 
	print "Loading CELEX lemmas to fetch lemmas.\n";
	loadLemmas(@restrictors);
	%lemmas = getLemmas();
    }
    my %freq = getUnigrams($corpus, %lemmas);
    
    foreach $factor_name (@factornames) {
	my $freqfactor_name = "JFQ".getFactorNameInfix().$factor_name;		
	my $lcpfactor_name = "CndP".getFactorNameInfix().$factor_name;		
	
	my $FID = getFactorID($factor_name, %cases);			# ID of variable in the output file (i.e. column)
	
	%cases = createFactor($freqfactor_name, %cases);
	my $freqFID = getFactorID($freqfactor_name, %cases);
	%cases = createFactor($lcpfactor_name, %cases);
	my $lcpFID = getFactorID($lcpfactor_name, %cases);

	############################################################################
	# Read in joint probabilities of factor_name value and event in the database
	#   If lemma information has been specified (i.e. if restrictors have been
	#   specified), use lemma information, otherwise use wordform information.
	############################################################################
	my %jfreq;
	foreach $id (keys %cases) { 
	    if ($id ne getHeaderID()) { 
		my ($words, $n) = lemmatizeNgramString(standardizeNgramString(removeNITEID($cases{$id}[$FID])));
		$jfreq{$words}++;
	    } 
	}
	
	my $count_found = 0;
	my $count_notfound = 0;
	my $count_nolemma = 0;
	foreach $id (keys %cases) {
	    if ($id ne getHeaderID()) {
		$cases{$id}[$freqFID] = "";			# initialize values since the cells may not be empty 
		$cases{$id}[$lcpFID] = "";			#   (even if the are 'emptyValue()'
		
		my ($words, $n) = lemmatizeNgramString(standardizeNgramString(removeNITEID($cases{$id}[$FID])));
		$nolemmacount += $n;

		if ($freq{$words} > 0 && $words ne "") { 
		    $cases{$id}[$freqFID] = $jfreq{$words};
		    $cases{$id}[$lcpFID] = $jfreq{$words} / $freq{$words};
		    $count_found++;
		}
		else { 
		    if ($warnings) { warn formatWarning("Frequency of $words (variable value $cases{$id}[$FID]) at case $id is zero!\n"); }
		    $count_notfound++;
		}
	    }
	}
	printLine("Found information for $count_found cases.");
	if ($OPT_lemmatize && $count_nolemma > 0) { print formatWarning("No lemma information was found for $count_nolemma cases. Word forms used instead (see -w for more detail).", 0) };
	if ($count_notfound > 0) { printLine("No information could be calculated for $count_notfound unobserved cases (see -w for more detail)."); }
    }
    writeFactorHash(%cases);
}
printFooter();
