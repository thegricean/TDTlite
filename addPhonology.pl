#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";
require "resources.pl";

my $version = "v.29";

my $dictionary_file = getPronunciationFile();
my %PHON;									# hash for phonology
my %SYLS;									# hash for syllable structure

##############################################################
# NB: with version .26 the syntax for factornames has changed!
# see format.pl, -f option
##############################################################

printVersionHeader("AddPhonology $version");
if ($help) { printHelp("addPhonology"); }
elsif ($corpus eq "") { printAbort();}
else {
    my %cases = parseFactorHash();
    
    open (DICTIONARY, $dictionary_file) || die "Cannot open dictionary file $dictionary_file for read!\n";
    print "\tReading in phonological dictionary information (CMU database)...\n";
    while (<DICTIONARY>) {
	chomp;
	if($_ =~ /^\w/) {				# consider only lines that represent a lexical entry
	    my ($wordform, $phon_string) = split(/\s\s/);
	    $wordform= lc($wordform);
	    
	    $PHON{$wordform} = $phon_string;	# phonological structure
	    $SYLS{$wordform} = $phon_string;	# syllable structure 
	    $SYLS{$wordform} =~ s/[^\d]//g;
	    $SYLS{$wordform} =~ s/(\d)(\d)/$1.$2/g;
	    $SYLS{$wordform} =~ s/(\d)(\d)/$1.$2/g;
	}
    }

    # extraction phon-information for each factor_name given
    foreach $factor_name (@factornames) {
	my $phonfactor_name = "PHON_".$factor_name;			# name of new variable for phonological structure
	my $phonfactor2aPLC_name = "PHONstartPLC_".$factor_name;	# name of new variable for phonological structure (PLACE)
	my $phonfactor2aMNR_name = "PHONstartMNR_".$factor_name;	# name of new variable for phonological structure (MANNER)
	my $phonfactor2bPLC_name = "PHONendPLC_".$factor_name;		# name of new variable for phonological structure (PLACE)
	my $phonfactor2bMNR_name = "PHONendMNR_".$factor_name;		# name of new variable for phonological structure (MANNER)
	my $sylsfactor_name = "SYLS_".$factor_name;			# name of new variable for syllable structure
	
	my $FID = getFactorID($factor_name, %cases);			# ID of variable in the output file (i.e. column)
	if ($FID eq "") {
	    warn "\tFATAL ERROR: Illegal Factor ID. Did not find factor $factor_name\n";
	    die;
	}
	print "\nFactor ID for factor '$factor_name': $FID\n";
	
	
	%cases = createFactor($phonfactor_name, %cases);
	my $phonFID = getFactorID($phonfactor_name, %cases);
	%cases = createFactor($phonfactor2aPLC_name, %cases);
	my $phon2aPLCFID = getFactorID($phonfactor2aPLC_name, %cases);
	%cases = createFactor($phonfactor2aMNR_name, %cases);
	my $phon2aMNRFID = getFactorID($phonfactor2aMNR_name, %cases);
	%cases = createFactor($phonfactor2bPLC_name, %cases);
	my $phon2bPLCFID = getFactorID($phonfactor2bPLC_name, %cases);
	%cases = createFactor($phonfactor2bMNR_name, %cases);
	my $phon2bMNRFID = getFactorID($phonfactor2bMNR_name, %cases);
	
	%cases = createFactor($sylsfactor_name, %cases);
	my $sylsFID = getFactorID($sylsfactor_name, %cases);
		
	print "\tAdding values to PHON and SYLS variables' ...\n";
	
	foreach $id (keys %cases) {
	    if ($id ne getHeaderID()) {
		$cases{$id}[$phonFID] = "";		# initialize values since the cells may not be empty
		$cases{$id}[$phon2aPLCFID] = "";
		$cases{$id}[$phon2aMNRFID] = "";
		$cases{$id}[$phon2bPLCFID] = "";
		$cases{$id}[$phon2bMNRFID] = "";
		$cases{$id}[$sylsFID] = "";
		
		my (@words)= split(/\s/,$cases{$id}[$FID]);
		foreach $word (@words) {
		    if ($PHON{$word} ne "") { 
			my (@phones) = split(/\s/,$PHON{$word});
			$l = @phones;
			if($cases{$id}[$phonFID] eq "") {				
			    $cases{$id}[$phon2aPLCFID] = getPlace($phones[0]);
			    $cases{$id}[$phon2aMNRFID] = getManner($phones[0]);
			}
			if($cases{$id}[$phonFID] eq "") {
			    $cases{$id}[$phon2bPLCFID] = getPlace($phones[$l-1]);
			    $cases{$id}[$phon2bMNRFID] = getManner($phones[$l-1]);
			}
			$cases{$id}[$phonFID] .= $PHON{$word}." ";
		    }
		    else { $cases{$id}[$phonFID] .= "XXX " };
		    if ($SYLS{$word} ne "") { $cases{$id}[$sylsFID] .= $SYLS{$word}."_" }
		    else { $cases{$id}[$sylsFID] .= "X_" };
		}
		$cases{$id}[$phonFID] =~ s/\s$//g;
		$cases{$id}[$sylsFID] =~ s/_$//g;	# if there is still a _ left at the end of the string, this indicates that 
		#    the last word was not found in the dictionary.
		$cases{$id}[$phonFID] =~ s/^(XXX)+$//g;	# remove X-mark if it's the only content (i.e. make cases NA).
		$cases{$id}[$sylsFID] =~ s/^x+$//g;	# remove X-mark if it's the only content (i.e. make cases NA).
	    }
	}
    }
    writeFactorHash(%cases);
}
printFooter();



########################################################################## SUBs
sub getPlace {
	my ($phon) = @_;
	my $place = "";

	if ($phon=~ /^[AEOUI]/) { $place = "vowel"}
	elsif ($phon=~ /^[PBM]/) { $place = "bilabial"}
	elsif ($phon=~ /^[FV]/) { $place = "labiodental"}
	elsif ($phon=~ /^[TD]H/) { $place = "dental"}
	elsif ($phon=~ /^[LR]|([TDNSZ]$)/) { $place = "alveolar"}
	elsif ($phon=~ /^[SZ]H/) { $place = "post-alveolar"}
	elsif ($phon=~ /^[Y]/) { $place = "palatal"}
	elsif ($phon=~ /^[W]/) { $place = "labio-velar"}
	elsif ($phon=~ /^[KG]|(NG)/) { $place = "velar"}
	elsif ($phon=~ /^[H]/) { $place = "glottal"};
	
	return $place;
}

sub getManner {
	my ($phon) = @_;
	my $manner = "";
	
	if ($phon=~ /^[AEOUI]/) { $manner = "vowel"}
	elsif ($phon=~ /^([BGPK])|([DT]$)/) { $manner = "plosive"}
	elsif ($phon=~ /^([CFJSVZH])|([DT]H)/) { $manner = "fricative"}
	elsif ($phon=~ /^[NM]/) { $manner = "nasal"}
	elsif ($phon=~ /^L/) { $manner = "lateral (approximant)"}
	elsif ($phon=~ /^[YWR]/) { $manner = "approximant"};
	
	return $manner;
}

