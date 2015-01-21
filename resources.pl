#!/usr/bin/perl

###############################
# reading in additional options
###############################
# defaul FactorNameInfix
$FactorNameInfix = "_";
# use part-of-speech based unigrams?
$OPT_pos = 0;
# use fluent unigrams?
$OPT_fluent = 0;
# use lemmas
$OPT_lemmatize = 0;
if ($options =~ /p/) { $OPT_pos = 1 };
if ($options =~ /f/) { $OPT_fluent = 1};
if ($options =~ /l/ || $lemmatize) { $OPT_lemmatize = 1};

####################################################
# CONSTANTS
####################################################
my $DATADIRECTORY = $ENV{'TDT_DATABASES'}."/";
if ($DATADIRECTORY eq "/") { 
    if ($warnings) { warn "No environment variable TDT_DATABASES found. Using default value.\n"; }
    $DATADIRECTORY = "databases/"; 
}
my $DICTIONARYFILE = $DATADIRECTORY."myCELEX.tab";
my $PRONUNCIATIONFILE = $DATADIRECTORY."c0.6";
my $CONVERSATIONFILE = $DATADIRECTORY."SWBD.tab";
my $XMLDIRECTORY = $ENV{'SWBD_XML_DATABASES'}."/";
if ($XMLDIRECTORY eq "/") { 
    warn "No environment variable SWBD_XML_DATABASES found. Using default value.\n"; 
    $XMLDIRECTORY = "/home/bcs-serve/p34/hlp/corpora/p-swbd/SWBD-xml-2-15-08/PAGE/Data/xml/"; 
}
my $XMLWORDDIRECTORY = $XMLDIRECTORY."words/";
my $UNIGRAMFILE_EXTENSION = ".1gram";         # redundant but backward compatible
my $GRAMFILE_EXTENSION = "gram";
my $POSGRAMFILE_TAG = "-POS";
my $FLUENTGRAMFILE_TAG = "-FLUENT";
my $NGRAMFILE_DELIM = "\t";                   # delimiter used in the ngram files 
my $NGRAM_DELIM = " ";                        # delimiter used by TDT
my $POS_DELIM = "%%";                         # delimiter used to attach POS information to words 

my $TOTALWORDCOUNT_KEY = "xxxTOTALCOUNTSxxx";
my $TOTALENTRIES_KEY = "xxxTOTALENTRIESxxx";

my %LEMMAS;                                   # hash to store lemmas in (makes multi-loading of lemmas unnecessary)
my @keysLEMMAS;
my $nLEMMAS;

####################################################
# GLOBAL SUBS below this points
####################################################

sub getDataDirectory {
    return $DATADIRECTORY;
}

sub getPronunciationFile {
    return $PRONUNCIATIONFILE;
}

sub getConversationFile {
    return $CONVERSATIONFILE;
}

sub getPOSDelim() {
    return $POS_DELIM;
}

sub getNgramDelim() {
    return $NGRAM_DELIM;
}

sub getFactorNameInfix() {
    return $FactorNameInfix;
}

sub setFactorNameInfix {
    my ($infix) = @_;
    
    $FactorNameInfix = $infix;
}

sub getTotalWordCountKey {
    ######################################################
    # return the key for the total word count as stored in
    # getUnigrams() or getNgrams()
    #
    ######################################################
    return $TOTALWORDCOUNT_KEY;
}


sub getTotalEntriesKey {
    ######################################################
    # return the key for the total entries as stored in
    # getUnigrams() or getNgrams()
    #
    ######################################################
    return $TOTALENTRIES_KEY;
}


sub getLemmas {
    return %LEMMAS;
}

sub getCELEXlemmas {
    my (@restrictors) = @_;
    if ($#restrictors < 0) { 
	if ($warnings) { warn "\tSUGGESTION: Maybe it would be better to use a lemma restrictors!\n\tContinue with empty restrictor set.\n"; }                      
	@restrictors = ("V", "N", "ADV", "SCON", "CCON", "PRP", "DT", "CD", "IN", "CC", "INTJ", "ABBREVIATION"); 
    }
    my %lemmas;
    my %wfreqs;
    ######################################################
    # reads in lemmas for corresponding spelling variants word forms from a 
    # modified version of the CELEX database. The lemmas are returned as a
    # hash (with wordforms as the keys)
    #
    #    @restrictors  :: an array of restrictions specifying the syntactic classes that lemmas can come from
    ######################################################
    open (DICTIONARY, $DICTIONARYFILE) || die "Cannot open dictionary file $DICTIONARYFILE for read!\n";
    print "\tReading in lemma information (from modified version of CELEX database)...\n";
    
    # how often has some lemma been seen before
    my $count_lemmadouble = 0;	
    while (<DICTIONARY>) {
	my ($wordform, $lemma, $class, $wfreq, @rest) = split(/\t/);
	my $ok = 0;
	my $count_lemmadouble = 0;
	
	########################################################################################################
	# Write new lemma info IFF current written lemma frequency is higher than currently stored written lemma 
	# frequency (NB: this is also the case when NO lemma had been found for that word form). So, this means
	# that lemma info is stored if it's the first match found or if the match has a higher frequency. The 
	# latter is done because it means that in case of ambiguity, the chance is higher that the right lemma is
	# chosen (simply because it's the more frequent one, kinda ;-).
	########################################################################################################
	if (exists($lemmas{lc($wordform)})) { 
	    if ($warnings) { warn "\tWARNING: Wordform $wordform for lemma $lemmas{lc($wordform)} has been encountered before.\n" };
	    $count_lemmadouble++;
	}
	
	if (!$wordform || (exists($wfreqs{lc($wordform)}) && $wfreqs{lc($wordform)} >= $wfreq)) { next; }
	foreach (@restrictors) { if ($class eq $_) { $ok = 1; last; }; }
        # ignore lemma if it doesn't match restrictor criteria  
	if (!$ok) { next; } 
	
	if ($warnings && exists($lemmas{lc($wordform)})) { warn "\t         Since the newly found lemma entry has a higher frequency, it will be substituted for the old one.\n" };
	$wfreqs{lc($wordform)} = $wfreq;			   
	$lemmas{lc($wordform)} = lc($lemma);
    }
    if ($count_lemmadouble > 0) { print "$count_lemmadouble word forms matched several lemma entries. In each case the lemma entry with the highest CELEX frequency was chosen (see -w for details).\n\n" };

    $nlemmas = (keys %lemmas) + 1;
    print "\t$nlemmas lemmas from $#restrictors classes loaded.\n";
    return %lemmas;
}

sub loadLemmas {
    my (@restrictors) = @_;

    %LEMMAS = getCELEXlemmas(@restrictors);
    @keysLEMMAS = keys %LEMMAS;
    $nLEMMAS = $#keysLEMMAS;
}


sub getCELEXPOSlemmas {
    my %lemmas;
    ######################################################
    # reads in lemmas for corresponding spelling variants word forms from a 
    # modified version of the CELEX database. One entry for each POS, lemma 
    # is returned all combined in a hash (with wordforms as the keys)
    #
    ######################################################
    
    open (DICTIONARY, $DICTIONARYFILE) || die "Cannot open dictionary file $DICTIONARYFILE for read!\n";
    print "\tReading in lemma information (from modified version of CELEX database)...\n";
    
    my $count_lemmadouble = 0;				# how has some lemma been seen before
    while (<DICTIONARY>) {
	my ($wordform, $lemma, $class, @rest) = split(/\t/);
	my $count_lemmadouble = 0;
	
	########################################################################################################
	# Write new lemma info IFF current written lemma frequency is higher than currently stored written lemma 
	# frequency (NB: this is also the case when NO lemma had been found for that word form). So, this means
	# that lemma info is stored if it's the first match found or if the match has a higher frequency. The 
	# latter is done because it means that in case of ambiguity, the chance is higher that the right lemma is
	# chosen (simply because it's the more frequent one, kinda ;-).
	########################################################################################################
	if (exists($lemmas{lc($wordform)}{$class})) { 
	    if ($warnings) { 
		warn "\tWARNING: Wordform $wordform with POS $class for lemma $lemmas{lc($wordform)}{$class} has been encountered before.\n"; 
	    }
	    $count_lemmadouble++;
	} 
	$lemmas{lc($wordform)}{$class} = lc($lemma);			   
    }
    if ($count_lemmadouble > 0) { print "$count_lemmadouble word forms matched several lemma entries. In each case the lemma entry with the highest CELEX frequency was chosen (see -w for details).\n\n" };
    print "\t$#{keys(%lemmas)} lemmas from $#restrictors classes loaded.\n";
    
    return %lemmas;
}

sub checkLemmaLoaded {
    ######################################################
    # defines default action if LEMMAS are not loaded
    # 
    # NB: does *not* check whether LEMMAS *should* have been
    #     loaded
    ######################################################

    if ($nLEMMAS < 0) {
        if ($warnings) { warn "Attempt to lemmatize before lemmas were loaded. Loading lemmas now.\n"; }
        loadLemmas();
    }
}


sub standardizeString {
    my ($s, $delim) = @_;
    my $newstring = "";
    ######################################################
    # convert string to lower case, except for potential
    # part-of-speech marking at end of string
    ######################################################

    foreach (split($delim, $s)) {
	if ($_ =~ /$POS_DELIM/) {
	    my ($word, $pos) = split($POS_DELIM, $_);
	    $newstring .= lc($word).$POS_DELIM.uc($pos).$delim;
	}
	else { $newstring .= lc($_).$delim; }
    }
    $newstring =~ s/$delim$//;

    return $newstring;
}

sub standardizeSentenceString {
    my ($s) = @_;

    return standardizeString($s, " ");
}

sub standardizeNgramString {
    my ($s) = @_;

    return standardizeString($s, $NGRAM_DELIM);
}


sub lemmatizeNgramString {
    my ($words) = @_;
    my $wf = "";
    my $nolemmacount = 0;

    checkLemmaLoaded();

    # if there is information on a lemma, take it
    #   otherwise estimate by using the wordform
    if ($OPT_lemmatize) {
	foreach $w (split($NGRAM_DELIM, $words)) {
	    if ($OPT_pos) {
		# split "words" into word and part-of-speech (POS)
		my ($word, $pos) = split($POS_DELIM, $w);
		if (exists($LEMMAS{$word})) { $wf .= $LEMMAS{$word}.$POS_DELIM.$pos; }
		else {
		    if ($warnings) { warn "\tWARNING: No lemma information found for word $word.\n"; }
		    $nolemmacount++;
		}
	    }
	    elsif (exists($LEMMAS{$w})) { $wf .= $LEMMAS{$w}; }
	    else {
		$wf .= $w;
		if ($warnings) { warn "\tWARNING: No lemma information found for word $word.\n"; }
		$nolemmacount++;
	    }
	    $wf .= $NGRAM_DELIM;
	}
	$words = $wf;
	# remove final delimiter
	$words =~ s/$NGRAM_DELIM$//;
    }

    return ($words, $nolemmacount);
}


sub getNgramFileName {
    my ($corpus, $n) = @_;

    if ($OPT_pos && $OPT_fluent) {
	$ngramfile = $DATADIRECTORY.$corpus.$FLUENTGRAMFILE_TAG.$POSGRAMFILE_TAG.".".$n.$GRAMFILE_EXTENSION;
    }
    elsif ($OPT_pos) {
	$ngramfile = $DATADIRECTORY.$corpus.$POSGRAMFILE_TAG.".".$n.$GRAMFILE_EXTENSION;
    }
    elsif ($OPT_fluent) {
	$ngramfile = $DATADIRECTORY.$corpus.$FLUENTGRAMFILE_TAG.".".$n.$GRAMFILE_EXTENSION;
    }
    else {
	$ngramfile = $DATADIRECTORY.$corpus.".".$n.$GRAMFILE_EXTENSION;
    }
    
    return $ngramfile;
}

sub getNgrams {
    my ($corpus, $n) = @_;

    my %ngrams;
    my $totalfreq= 0;
    ######################################################
    # reads in ngram information form the specified file and returns a 
    # hash (with wordforms as keys). If a hash of %lemmas (wordform-to-
    # lemma mappings) is provided to the function
    # those are used to gather the total count for all tokens associated
    # with the LEMMAs (rather than wordforms). The ngram provided for each
    # string of wordforms is then the ngram of the corresponding combination 
    # of lemmas.
    # This function now (v.34) also handles ngram files with part-of-speech (POS) 
    # information.
    #
    #
    # NB: the total word count is returned in the hash with 
    # the key getTotalWordCountKey()
    ######################################################

    ######################################################
    # select what ngrams to load
    # depending on the value of several flags that can be set
    # by the user through calling any of the ngram adding
    # PERL scripts.
    ######################################################
    if ($OPT_lemmatize) {
        checkLemmaLoaded();
        if ($OPT_pos && $OPT_fluent) {
            print "Getting part-of-speech-based lemma frequencies for fluent parts of corpus.\n";
            setFactorNameInfix("_LFP_");
         }
        elsif ($OPT_pos) {
            print "Getting part-of-speech-based lemma frequencies.\n";
            setFactorNameInfix("_LP_");
	}
        elsif ($OPT_fluent) {
            print "Getting lemma frequencies for fluent parts of corpus.\n";
            setFactorNameInfix("_LF_");
	}
        else {
            print "Getting lemma frequencies.\n";
            setFactorNameInfix("_L_");
        }
    }
    else {
        if ($OPT_pos && $OPT_fluent) {
            print "Getting part-of-speech wordform frequencies for fluent parts of corpus.\n";
            setFactorNameInfix("_FP_");
        }
        elsif ($OPT_pos) {
            print "Getting part-of-speech-based wordform frequencies.\n";
            setFactorNameInfix("_P_");
	}
        elsif ($OPT_fluent) {
            print "Getting wordform frequencies for fluent parts of corpus.\n";
            setFactorNameInfix("_F_");
        }
        else {
            print "Getting wordform frequencies.\n";
            setFactorNameInfix("_");
        }
    }

    open (NGRAM, getNgramFileName($corpus, $n)) || die "Cannot open Ngram file ".getNgramFileName($corpus, $n)." for read!\n";
    print "\tReading in frequency information from $ngramfile ...\n";
    while (<NGRAM>) {
        chomp;
	if(($OPT_pos && $_ =~ /^\s*(\d*)\s(.*$POS_DELIM.*)$/) || $_ =~ /^\s*(\d*)\s(.*)$/) {
	    my $freq = $1;

            # split the ngram into words, then format it
            my @words = split(/\s+/, $2);
            @words = map {standardizeNgramString($_)} @words;
            my $wordforms = join($NGRAM_DELIM, @words);

            # Florian's way
            # my $wordforms = standardizeNgramString($2);

	    my $wf;

	    # if there is information on a lemma, take it
	    #   otherwise estimate by using the wordform
	    if ($OPT_lemmatize) {
		foreach $w (split($NGRAM_DELIM, $wordforms)) {
		    if ($OPT_pos) {
			# split "wordform" into word and part-of-speech (POS)
			my ($word, $pos) = split($POS_DELIM, $w);
			if (exists($LEMMAS{$word})) { $wf .= $LEMMAS{$word}.$POS_DELIM.$pos; }
		    }
		    elsif (exists($LEMMAS{$w})) { $wf .= $LEMMAS{$w}; }
		    else { $wf .= $w; }
		    $wf .= $NGRAM_DELIM;
		    $wordforms = $wf;
		}
		
		# remove final delimiter
		$wordforms =~ s/$NGRAM_DELIM$//;
	    }

	    $wordforms =~ s/$NGRAMFILE_DELIM/$NGRAM_DELIM/g;  # convert delimiters
# warn "$freq _ $wordforms";
	    $ngrams{$wordforms} += $freq;
	    $totalfreq += $freq;
	}
    }
    close NGRAM;

    my @nkeys = (sort keys %ngrams);
    my $numngrams = $#nkeys + 1;
    print "Counted ${numngrams} entries representing ${totalfreq} tokens.\n";
    $ngrams{getTotalWordCountKey()} = $totalfreq;

    return %ngrams;
}

sub getUnigrams {
    my ($corpus) = @_;
    return getNgrams($corpus, 1);
}

sub getBigrams {
    my ($corpus) = @_;
    return getNgrams($corpus, 2);
}


sub getWordTimeInfo {
    my ($conversation) = @_;
    ############################################################
    # Reads in information from XMLWORDDIRECTORY and returns
    # the lines as a hash. The keys have the form "swNNNN_sN+_N+
    # where NNNN is the swbd conversation ID and the remainder 
    # is the terminal ID from the xml corpus (unique within a 
    # conversation).
    ############################################################

    if ($conversation eq "") { print "\nReading in xml file names.\n"; }
    else { print "\nReading in xml file names for conversation $conversation.\n"; }

    opendir XMLWORDDIR, $XMLWORDDIRECTORY;
    my $l = 0;
    my @files;
    while ($file = readdir(XMLWORDDIR)) {
	# if no conversation is specified all files are read;
	# otherwise, only files for the specified conversation are read
	if (($conversation eq "" && $file =~ /words.xml$/) || ($conversation ne "" && $file =~ /$conversation.*words.xml$/)) {
	    push(@files, $file);
	    $l++;
	}
    }
    closedir XMLWORDDIR;

    print "Reading in information from $l xml files.\n";
    my %xmlword;
    $l = 0;
    foreach $file (@files) {
        $file =~/(sw\d{4})/;
        my $conversation = $1;
        $file = $XMLWORDDIRECTORY.$file;

        open(XMLWORDFILE, "<$file") || open(XMLWORDFILE, "<$file") || die "Cannot open $file\n";
        while (<XMLWORDFILE>) {
            $_ =~ /<word (.+nite:id=\"([^\"]+)\".+)>$/;
            my $id = $conversation."_".$2;
            # print "$id\n";

            if (exists($xmlword{$id})) { warn "\tWARNING: Nite ID $id is not non-unique!\n"; }
	    $xmlword{$id} = $1;
	    $l++;
	}
        close(XMLWORDFILE);
    }
    print "Read in $l terminals.\n";
    return %xmlword;
}


1;
