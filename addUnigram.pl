#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";
require "resources.pl";

my $version = "v.3";

my %lemmas;

printVersionHeader("AddUnigram $version");
if ($help) { printHelp("addUnigrams"); }
elsif ($corpus eq "" || $#factornames < 0) { printAbort(); }
else {
    my %cases = parseFactorHash();
    if ($OPT_lemmatize) {
        print "Loading CELEX lemmas to fetch lemmas.\n";
	loadLemmas(@restrictors);
        %lemmas = getLemmas();
    }
    my %freq = getUnigrams($corpus);
    my $totalcount = $freq{getTotalWordCountKey()};		
    # get the total word count from the unigram hash

    foreach $factor_name (@factornames) {
	my $freqfactor_name = "FQ".getFactorNameInfix().$factor_name;		
	my $lpfactor_name = "P".getFactorNameInfix().$factor_name;		
	
        # ID of variable in the output file (i.e. column)
	my $FID = getFactorID($factor_name, %cases);	     	
	
	%cases = createFactor($freqfactor_name, %cases);
	my $freqFID = getFactorID($freqfactor_name, %cases);
	%cases = createFactor($lpfactor_name, %cases);
	my $lpFID = getFactorID($lpfactor_name, %cases);
	

        my $count = 0;
        my $nacount = 0;
        my $nolemmacount = 0;
	foreach $id (keys %cases) {
	    if ($id ne getHeaderID()) {
		# initialize values since the cells may not be empty (even if the are 'emptyValue()')
		$cases{$id}[$freqFID] = "";
		$cases{$id}[$lpFID] = "";
		
                my $words = removeNITEID($cases{$id}[$FID]);       
		foreach $word (split(/\s/, $words)) {
		    my ($word, $n) = lemmatizeNgramString(standardizeNgramString($word));
		    $nolemmacount += $n;
# if ($OPT_pos) {warn "$words\t$word";}
		    if ($freq{$word} ne "") {
			# in order to get rel. probs get $totalfreq from getUnigrams() and divide by it by $totalfreq
			$cases{$id}[$freqFID] .= $freq{$word}." ";
			$prob = $freq{$word} / $totalcount;
			$cases{$id}[$lpFID] .= $prob." ";
			$count++;
		    }
		    else { 
			$cases{$id}[$freqFID] .= "X ";
			$cases{$id}[$lpFID] .= "X ";
			$nacount++;
		    }
		}
		$cases{$id}[$lpFID] =~ s/\s$//g;
		$cases{$id}[$lpFID] =~ s/^X+$//g;
	    }
	}
	print "\nFound information for $count cases.\n";
        if ($OPT_lemmatize) { print "No lemma information was found for $nolemmacount cases. Word forms used instead (see -w for more detail).\n" };
        if ($nacount > 0 ) { print "No information could be calculated for $nacount unobserved cases (see -w for more detail).\n"; }
    }
    writeFactorHash(%cases);
}
printFooter();
