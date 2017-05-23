#!/usr/bin/perl

use Getopt::Long;
Getopt::Long::Configure ("bundling");
####################################################
# CONSTANTS
####################################################
my $FORMATVERSION = "v0.35.1";
my $RESOURCEVERSION = "0.39";
my $HELPFILEDIRECTORY = $ENV{'TDT_HELP'}."/";
if ($HELPFILEDIRECTORY eq "") { 
    # No environment variable TDT_HELP found. Using default value. 
    $HELPFILEDIRECTORY = "man/"; 
}
my $MAINHELPFILE= "format.hlp";
my $HELPFILE_EXTENSION= ".hlp";
my $FILE_EXTENSION = ".tab";
my $PATTERNFILE_EXTENSION = ".ptn";
my $DATAFILE_EXTENSION = ".t2o";
my $HEADER_ID = "Item_ID";
my $DELIM = "\t";
my $EMPTY_STRING = "";
my $EOS = "._EOS";

####################################################
# GLOBAL VARIABLES
####################################################
$numwarnings = 0;

####################################################
# GLOBAL OPTIONS
####################################################
my $DATABASENAME = "";
$corpus = "";
$help = 0;
$about = 0;   			# switch to 1 for public releases
$warnings = 0;
$overwrite = 0;
$reset = 0;
$lemmatize = 0;
$TextVar = "Conversation_ID";
$UnitVar = "TURNinCONV";
$ClauseVar = "TOPinCONV";
%options = (	'help' => \$help, 'h' => \$help, 
		'about' => \$about,
		'warnings' => \$warnings, 'w' => \$warnings, 
		'overwrite' => \$overwrite, 'o' => \$overwrite, 
		'reset' => \$reset, 'r' => \$reset, 
		'corpus' => \$corpus, 'c' => \$corpus,
                'noversion' => \$noversion,
		'default' => \$default, 
		'opts' => \$options, 
		'TextVar' => \$TextVar, 'UnitVar' => \$UnitVar, '$ClauseVar' => \$ClauseVar,
		'BreakVar' => \$BreakVar, 'PrimeHeadVar' => \$PrimeHeadVar,
		'Domain' => \$Domain
);
@factornames;
@factorfiles;
@restrictors;
@cols;
@colnames;
GetOptions( \%options, 'help!', 'h', 
	    'about!', 
	    'warnings!', 'w', 
	    'overwrite!', 'o', 
	    'reset!', 'r',
	    'noversion!',                    # don't print the version
	    'default=s',                     # provide a default for any value that is not set
	    'opts=s',                        # a way to hand arbitrary options to different programs
	    'c|corpus=s',                    # name of the corpus
	    'f|factors=s' => \@factornames,  # name of the variables in the database that are being modified
	    'restrictors=s' => \@restrictors,# set of restrictors used for lemmatizer
	    'lemmatize!' => \$lemmatize,     # deprecated: now handled in resources.pl via $options 
	    'files=s' => \@factorfiles,
	    'd|database=s' => \$DATABASENAME,# name of database
	    'cols=s' => \@cols,
	    'colnames=s' => \@colnames,
	    'TextVar=s',                     # obligatory options for priming script
	    'UnitVar=s',
	    'ClauseVar=s',
	    'Domain=s',
            'BreakVar=s', 'PrimeHeadVar=s'   # optional options for the priming
);

@factornames = split(",", join(",", @factornames));
# if factornames are empty take the remaining arguments instead 
# (should ensure backward compatibility)
@factorfiles = split(",", join(",", @factorfiles));

for ($i=0; $i <= $#factornames; $i++) {
    my ($factor, $file) = split("=", $factornames[$i]);
    $factornames[$i] = $factor;
    if ($file ne "") {
	if ($factorfiles[$i] ne "" && $warnings) { warn formatWarning("Double specification of ${i}th filename. Taking value from -f option."); }
	$factorfiles[$i] = $file;
    }
}
for ($i=0; $i <= $#factorfiles; $i++) {
    if ($factorfiles[$i] !~ /\..+$/) { $factorfiles[$i] = $factorfiles[$i].$DATAFILE_EXTENSION; }
}

$NUM_factornames = $#factornames + 1;
$NUM_factorfiles = $#factorfiles + 1;
    
@restrictors = split(",", join(",", @restrictors));
@cols = split(",", join(",", @cols));
@colnames = split(",", join(",", @colnames));

# output file (the database)
if (getDatabaseName() eq "") { $DATABASENAME = $corpus.getFileExtension(); }


######################### Implicational relations between options ######################
if ($#restrictors > -1) { $lemmatize = 1 };                                     # for backward-compatibility
if ($reset) { $overwrite = 1 };
if ($corpus =~ /^swbd/i) { $corpus = "swbd"; }
elsif ($corpus =~ /^swbdext/i) { $corpus = "swbdext"; }
elsif ($corpus =~ /^wsj/i) { $corpus = "wsj"; }
elsif ($corpus =~ /^brown/i) { $corpus = "brown"; }
elsif ($corpus =~ /^bncs/i) { $corpus = "bncs"; }  
elsif ($corpus =~ /^bncw/i) { $corpus = "bncw"; }  
elsif ($corpus =~ /^bnc/i) { $corpus = "bnc"; }
elsif ($corpus =~ /^negra/i) { $corpus = "negra"; }
elsif ($corpus =~ /^wiki/i) { $corpus = "wiki";}
else { $corpus = "unknown"; }
#if (exists($options{factors})) { $factor_name = $options{factors}[0]; }        # setting the default for $factor_name
########################################################################################

$NUM_args = @ARGV;

if ($warnings) { use warnings; }
if ($about) {
	warn "\n";
	warn "#######################################################################################\n";
	warn "# You are using an alpha release of the Tgrep2 Database Tools $FORMATVERSION                #\n";
	warn "#                                                                                     #\n";
	warn "# Please cite: Jaeger, T.F. 2005-7. TDT, http://www.bcs.rochester.edu/people/fjaeger/ #\n";
	warn "# PLEASE DO NOT DISTRIBUTE; (c) 2005-2007 tiflo\@csli.stanford.edu                     #\n";
	warn "# For now, the use of Tgrep2 Database Tools is restricted to Stanford                 #\n";
	warn "#######################################################################################\n\n";
}

####################################################
# GLOBAL SUBS below this points
####################################################

sub formatWarning {
    my ($m, $level) = @_;
    ################################################
    # provivedes a uniform format for warnings 
    # 
    # a level can be specified (1 being the lowest)
    ################################################

    if ($level == 3) { return "\tURGENT WARNING: $m\n"; }
    else { return return "\tWARNING: $m\n"; }
}

sub emptyValue {                # returns the empty string/value
    return $EMPTY_STRING;
}


sub getEOS {                    
    # returns end-of-sentence symbol (for ngrams, etc.)
    return $EOS;
}

sub getFormatVersion() {
    return $FORMATVERSION;
}

sub getResourceVersion() {
    return $RESOURCEVERSION;
}

sub getTDTVersion() {
    return "TDT ".getFormatVersion().":".getResourceVersion();
}

sub Version {
    my ($programversion) = @_;
    return $programversion." [".getTDTVersion()."]";
}

sub getFileExtension {		# returns the file extension
    return $FILE_EXTENSION;
}

sub getPatternFileExtension {          # returns the file extension                                                                        
    return $PATTERNFILE_EXTENSION;
}

sub getDataFileExtension {          # returns the file extension                                                                        
    return $DATAFILE_EXTENSION;
}

sub getDatabaseName {		# returns the database name
    return $DATABASENAME;
}

sub getDelimiter {		# returns the file extension
    return $DELIM;
}

sub getHeaderID {
    return $HEADER_ID;	
}

sub disfluentCorpus {
    if ($corpus eq "swbd" | $ corpus eq "bncs") { return 1; }
    else { return 0; }
}


sub printLine {
    my ($line) = @_;
    print "$line\n";
}

sub printStarDivider {
    printLine("************************************************************");
}

sub printLineDivider {
    printLine("------------------------------------------------------------");
}

sub printBox {
    my ($line) = @_;
    printStarDivider();
    printLine("* ".$line);
    printStarDivider();
}

sub printFooter {
    if ($numwarnings > 0 ) { printLine("WARNING: There were $numwarnings warning(s) (use -w for more detail)."); }
    printLineDivider();
}

sub printVersionHeader {
    my ($programversion) = @_;

    print "\n";
    printBox(Version($programversion));
    printLine("Adding information for $NUM_factornames variable(s) from $NUM_factorfiles input file(s).");      
    printLine();
}

sub printHelp {
	my ($filename) = @_;
	
	printLine("Program NOT executed. Printing help file instead.\n");
	open FILE, $HELPFILEDIRECTORY.$filename.$HELPFILE_EXTENSION or die "Cannot open help file for $filename!\n";
	while (<FILE>) { print $_; }
	print "\n";
	
	open HELPFILE, $HELPFILEDIRECTORY.$MAINHELPFILE or die "Cannot open main help file $MAINHELPFILE!\n";
	while (<HELPFILE>) { print $_; }
	print "\n";
}


sub printAbort {
	print "\n\t####################################################\n";
	print "\t# ERROR: Insufficient or wrong arguments provided. #\n";
	print "\t#        Use --help (-h) for help                  #\n";
	print "\t#        Program terminated.                       #\n";
	print "\t####################################################\n\n";
	die;
}


sub getFactors {
    my $factor_file= shift;	# factor file
    my @FACTORS;

    open(FILE, $factor_file) || die "Could not open the variable file $factor_file: $!\n";
    while (<FILE>) {
	my $factor= $_;
	$NUM_FACTORS++;
	$FACTORS[$NUM_FACTORS]= $factor;
    }
    return @FACTORS;
}

sub getFactorID {
    my ($factor, %factors) = @_;
    my $factorID = 0;
    my $foundsomething = 0;

    foreach (@{ $factors{$HEADER_ID} }) {
	if ($_ eq $factor) { 
		$foundsomething = 1;
		return $factorID;
	}
	$factorID++;
    }
    if ($foundsomething == 0 && @{ $factors{$HEADER_ID} } > 0) { die "\tFATAL ERROR: Illegal variable ID. Did not find variable $factor. Maybe use -o option?\n"; }
}

sub getFactorLevels {
    	my ($factor, %factors) = @_;
    	my $factorID = getFactorID($factor, %factors);
	######################################################
	# returns all levels of a factor as an array.
	# 
	#    $factor  :: name of factor
	#    %factors :: hash with all cases
	######################################################

	my @levels;
   	foreach $id (keys %factors) {
   		if ($id ne getHeaderID()) { 
   			my $found = 0;
   			if (@levels == 0) { 
   				$levels[0]= $factors{$id}[$factorID]; 
   				next;
   			}
			foreach (@levels) { 
				if ($_ eq $factors{$id}[$factorID]) {
					$found = 1;
					last;
				}
			}
			if ($found == 0) { push(@levels, $factors{$id}[$factorID]) };
   		}
	}
	return @levels;
}


sub getNumOfFactors {
    my (%factors) = @_;		# corpus file

    my $numFactors = @{ $factors{$HEADER_ID} };
    if ($numFactors eq "") { $numFactors = 0 };
    return $numFactors;
}


sub getNumOfCases {
    my (%factors) = @_;		# corpus file

    my @keys = keys %factors;
    return $#keys; # - 1 for header, + 1 because $# counts length -1
}


sub createFactorHash {
    my @headerrow;
    my %created_factor_hash = (
			       $HEADER_ID => @headerrow,
			       );
    return %created_factor_hash;
}


sub createFactorName {
    my ($factor_name, $starttag, $endtag, $connector) = @_;
    if ($connector eq "") { $connector = "_"; }
    
    my $start = "";
    my $end = "";
    if ($starttag ne "") { $start = $starttag.$connector; }
    if ($endtag ne "") { $start = $connector.$endtag; }

    #####################################################
    # provides normed names for factors that follow some 
    # kind of naming scheme defined in this function. 
    # the main purpose of this function is too allow users
    # to later define their own naming schemes
    #####################################################

    return $start.$factor_name.$end;
}


sub createFactor { 	
    my ($newfactor_name, %factors) = @_;
    my $emptyValue = emptyValue();
    my $newFID = "";						# (v.28.7-t-v.28.8 BUX FIX)
    my $factorID = 0;
    my $alreadyexisted = 0; 
    ######################################################
    # returns hash with all cases and the newly created factor
    # 
    #    $newfactor  :: name of factor to be created
    #    %factors    :: hash with all cases
    #
    # Note: this procedure does not itself write anything into the file. Use print factors for that.
    ######################################################

    foreach $factorname (@{ $factors{getHeaderID()} }) {
	if ($factorname eq $newfactor_name) { 
	    $newFID = $factorID;
	    last;						# (v.26-to-v.27 BUG FIX)
	}
	$factorID++;
    }
    
    if ($newFID ne "") { $alreadyexisted = 1 };
    if ($alreadyexisted == 1) {
	$numwarnings++;
	if ($warnings) { warn "\n\tWARNING: Variable $newfactor_name already exists (variable ID is $newFID)\n" };
	
	if (!$reset && !$overwrite) { die "\tERROR: Full cell found, but neither -o nor -r options was selected (use -w for more detail). Program will exit.\n\n"; }
	elsif ($warnings && $reset) { warn "\t         As requested (-r), all values will be reset to '$emptyValue'.\n\n"; }
	elsif ($warnings && $overwrite) { warn "\t         As requested (-o), old values may be overwritten.\n\n" };
	
	print "Using existing variable $newfactor_name for output (variable ID $newFID)\n";
    }
    else {
	$newFID= getNumOfFactors(%factors);
	while ($newFID > 0 && $factors{$HEADER_ID}[$newFID - 1] !~ /^[a-zA-Z]/i) { $newFID--; };
	print "Created new variable $newfactor_name (variable ID $newFID)\n";
    }
    
    if ($reset || $alreadyexisted == 0) {				# write empty cells into factor column only if it 
	#   was just created or if reset is switch on
	foreach (keys %factors) {
	    if ($_ eq $HEADER_ID) { $factors{$_}[$newFID] = $newfactor_name; }
	    else {$factors{$_}[$newFID] = emptyValue();}	
	}
    }
    return %factors;
}


sub addDefault {
    my ($factor_name, %factors) = @_;
    my $FID = getFactorID($factor_name, %factors);
        ######################################################
        # replaces all empty values with default specified by $default
        #
        #    $factor_name:: name of factor to be modified
        #    %factors    :: hash with all cases
        ######################################################

    foreach (keys %factors) {
	if ($_ ne $HEADER_ID && $factors{$_}[$FID] eq emptyValue()) { $factors{$_}[$FID] = $default;}
    }
    if ($warnings) { warn "Default '$default' added to all empty cells of variable '$factor_name'\n"; }
    return %factors;
}


sub parseNITEID {
    my ($line) = @_;
    ######################################################
    # Parses out and returns nite::id out of a string
    ######################################################
    
    if ($line =~ /^.*(sw\d+_s\d+_\d+)/) { return $1; }
    else { return 0; }
}

sub removeNITEID {
    my ($line) = @_;
    ######################################################
    # Removes nite::id from a string
    ######################################################
    
    if ($line =~ /^(.*)\*sw\d+_s\d+_\d+/i) { return $1; }
    else { return $line; }
}


sub stripForPrint {
    my ($corpus, $line) = @_;
    ######################################################
    # Shortcut that calls strip function with print parameter 
    #   --> clitics like 's, n't, etc. will be conjoined to 
    #   their host. 
    ######################################################

    return strip($corpus, $line, 1, 1, 0, ".", "!", "?", ":", ";", ",", "\"", "--", "(", ")");
}

sub stripForWordCount {
    my ($corpus, $line) = @_;

    return strip($corpus, $line, 0, 0, 0, "", "", "", "", "", "", "", "", "", "");
}

sub stripForNgrams {
    my ($corpus, $line) = @_;

    ######################################################
    # the value of -1 for $joinclitics makes sure that even
    # if the original string has conjoined clitics, they 
    # are broken up by inserting a space between host and
    # clitic.
    ######################################################

    # delete quotes, mark sentence end, and replace all punctuation by .
    return strip($corpus, $line, -1, 0, 0, getEOS(), ".", ".", ".", ".", ".", "", ".", ".", ".");
}

sub strip {
    my ($corpus, $line, $joinclitics, $joinpunctuation, $leavetraces, $dotmarker, $exclamationmarker, $questionmarker, $colonmarker, $semicolonmarker, $commamarker, $quotemarker, $dashmarker) = @_;
    ######################################################
    # Corpus-specific strip function
    # 
    ######################################################

    chomp $line;

# my $oldline = $line;
# if ($oldline =~ /n't/) { warn "$oldline :::1::: $line\n"; }                

    $line =~ s/-NONE-//ig;
    if ($corpus =~ /^swbd/){
    	if (!$leavetraces) {
	    $line =~ s/-N\d(\d|[A-Z])+\S*//ig;
    	}
        # gets those odd cases where the speakerID has .1 attached to avoid identical speakerIDs (no idea why they are in the switchboard)
        $line =~ s/Speaker(A|B)\d*\.\d\*t\d*\.\d//ig;
    	$line =~ s/Speaker(A|B)\d*\*t\d*//ig;
	$line =~ s/-uncoded_[a-zA-Z]+//ig;	# e.g. -uncoded_status-uncoded_statustype-uncoded
    	$line =~ s/-uncoded//ig;		# order is important. Don't move this replace upwards
    	$line =~ s/_antec//ig;
    }
    else {
    	if (!$leavetraces) {
	    $line =~ s/\*T\*-\d*//ig;
	    $line =~ s/\*U\*-\d*//ig;
	    $line =~ s/\*U\*//ig;
	    $line =~ s/\*\?\*//ig;
	    $line =~ s/\*EXP\*-\d*//ig;
	    $line =~ s/\*ICH\*-\d*//ig;
	    $line =~ s/\*\.\*-\d*//g;
	    $line =~ s/\*-\d*//g;
	    $line =~ s/-(L|R)(R|C)B-//ig;
	}
   	$line =~ s/\*//g;
   	$line =~ s/^0\s//g;
	$line =~ s/^0$//g;
   	$line =~ s/\s0\s//g;
    }
    $line =~ s/\\\S*//g;
    $line =~ s/-ap//ig;

# if ($oldline =~ /n't/) { warn "$oldline :::2::: $line\n"; }                
    if ($joinclitics == 1) {
	$line =~ s/\sn\'t/n\'t/ig;                 # NOT
    	$line =~ s/\s\'(s|ve|d|ll|re|m)?/\'$1/ig;  # BE, HAVE, possessives (including ')
    }
    elsif ($joinclitics == -1) { 
	$line =~ s/([a-zA-Z])'(s|ll|re|m|ve|d)?[^a-zA-Z]/\1 '\2/ig;
	$line =~ s/n't/ n't/ig;
    }
    $line =~ s/\[//g;
    $line =~ s/\]//g;
    $line =~ s/\+//g;
    $line =~ s/(E|N)_S//ig;
	
# if ($oldline =~ /n't/) { warn "$oldline :::3::: $line\n"; }
    # some punctuation should always be separated by exactly one space 
    # from the surrounding symbols
    $line =~ s/[\"]/ $quotemarker/g;
    $line =~ s/''/ $quotemarker/g;
    $line =~ s/\`\`/ $quotemarker/g;
    if ($joinpunctuation) {
	$line =~ s/\s*[^0-9]\./$dotmarker/g;
	$line =~ s/\s*[!]/$exclamationmarker/g;
	$line =~ s/\s*[?]/$questionmarker/g;
	$line =~ s/\s*[:]/$colonmarker/g;
	$line =~ s/\s*[;]/$semicolonmarker/g;
	$line =~ s/\s*[^0-9][,]/$commamarker/g;
	$line =~ s/\-\-/$dashmarker/g;
	$line =~ s/\-/$dashmarker/g;      
 	$line =~ s/\s*\(\s*/ $obmarker/g;
	$line =~ s/\s*\)\s*/$cbmarker /g; 
    }
    else {
	# this used to be \s*, forcing punctuation to be separated from 
	# words. Unfortunately, this causes problems with abbreviations
	# like Mr., Corp., Inc., etc. 
	# Hence now, dots that are adjoined to a word are left like that.
	# (and similarly for dashes, which can occur in the middle of a 
	#  word)
        $line =~ s/\s+\./ $dotmarker/g;
	$line =~ s/\s+\-\-/ $dashmarker/g;
	$line =~ s/\s+\-/ $dashmarker/g;      
 	# if strings come in word-by-word, the above pattern will not
	# match. the following pattern catches those cases.
	$line =~ s/^\.$/$dotmarker/g;
	$line =~ s/^\-\-/ $dashmarker/g;
	$line =~ s/^\-/ $dashmarker/g;
	# since the remaining punctuation signs do not occur in abbreviations
	# one patterns for each of them is sufficient.
        $line =~ s/\s*[!]/ $exclamationmarker/g;
        $line =~ s/\s*[?]/ $questionmarker/g;
        $line =~ s/\s*[:]/ $colonmarker/g;
        $line =~ s/\s*[;]/ $semicolonmarker/g;
	# prevent commas within numbers from splitting the word
        $line =~ s/\s*[^0-9][,]/ $commamarker/g;
        $line =~ s/\s*\(\s*/ $obmarker /g;
        $line =~ s/\s*\)\s*/ $cbmarker /g; 
    }

    $line =~ s/^\s+//;				# strip initial spaces
    $line =~ s/\s+$//;				# strip final spaces
    $line =~ s/\s\s+/ /g;			# reduce multiple spaces to one space
# if ($oldline =~ /n't/) { warn "$oldline :::4::: $line\n"; }
    return "$line";
}


sub parseFactorHash {
    my ($file, %factors) = @_;
    unless ($file) { $file = getDatabaseName(); }
    ########################################################
    # parses the input file and creates a hash of factors.
    # 
    #   $file    :: the filename of the database to be read
    #   %factors :: the hash with all cases
    #
    # the factor-hash can be handed as an optional argument.
    # similarly, the file name can be handed as an argument
    # but it defaults to the database name (read in by 
    # format.pl)
    ########################################################
    open(FILE, $file) || die "\tFATAL ERROR: Could not open database file $file: $!.\n\tScript aborted.\n\n";

    $_ = <FILE>;
    chomp;
    my ($HEADER_ID, @factornames) = split(/$DELIM/);
    $factors{$HEADER_ID} = [ @factornames ];
    
    while (<FILE>) {
	chomp;
	my ($id, @factors) = split(/$DELIM/);
	$factors{$id} = [ @factors ];
    }

    print "The database contains ".getNumOfCases(%factors)." cases.\n";
    return %factors;
}


sub writeFactorHash {
    my (%factors) = @_;
    
    return writeFactorHashToFile("", %factors); 
}

sub writeFactorHashToFile {
    my ($file, %factors) = @_;
    if ($file eq "") { $file = getDatabaseName() };
    ##########################################################
    # prints the hash of factors (cases) into the output file.
    ##########################################################
    open (OUT, ">$file") || die "Couldn't open $file for output: $!\n";

    printLine();
    printLine("Printing data to $file ...");
    print OUT getHeaderID();
    foreach (@{ $factors{getHeaderID()} }) {
	print OUT "\t$_";
    }
    print OUT "\n";

    foreach $id (sort sortTGrep2ID keys %factors) {
	next if $id eq getHeaderID();
	print OUT $id;
	foreach (@{ $factors{$id} }) {
	    print OUT "\t$_";
	}
	print OUT "\n";
    }
}
 
sub printFactorHash {
    	my ($output, %factors) = @_;
	######################################################
	# obsolete - only maintained for backward compatibility
	######################################################

	writeFactorHash(%factors);
}


sub sortTGrep2ID {
    $a =~ /^(\d+):(\d+)$/;
    my $s_a = $1;
    my $t_a = $2;

    $b =~ /^(\d+):(\d+)$/;
    my $s_b = $1;
    my $t_b = $2;

    if ($s_a < $s_b) { return -1; }
    elsif ($s_a > $s_b) { return 1; }
    else {
	if ($t_a < $t_b) { return -1; }
	elsif ($t_a > $t_b) { return 1; }
	else { return 0; }
    }
}


###############################
# general SUBs below this point

sub print_table {
    my ($idname,$header,$delim,%hash) = @_;
    my (@names) = split(/$delim/,$header);

    $headerstring = join($delim, ($idname, @names));
    print "$headerstring\n";
    foreach $id (keys %hash) {
	if ($id ne $idname) {
		print "$id";
		foreach $name (@names) {
	    		print $delim;
	    		print $hash{"$id"}{$name};
		}
		print "\n";
	}
    }
}

#only works with files with headers
#first column has to be ID;
sub parse_table {
    my ($filename,$delim) = @_;
    warn "Reading $filename...\n";
    open (FILE,$filename) or die "Can't open $filename";
    my @lines = <FILE>;
    close(FILE);
    my $headerline = $lines[0];
    chomp($headerline);
    my ($idname, @names) = split(/$delim/,$headerline);
    warn "Treating $idname as unique identifier in $filename\n";
    $headerstring = join($delim, @names);
    my %hash; my $i; my $id; my @fields;
    #note: adds an entry for header line
    foreach $line (@lines) {
	chomp($line);
	($id, @fields) = split(/$delim/,$line);
	$i = 0;
	foreach $name (@names) {
	    $hash{"$id"}{$name} = $fields[$i];
	    $i++;
	}
    }
    return ($idname, $headerstring, %hash);
}


#first column has to be ID;
sub parseDelimFile {
    my ($filename,$delim) = @_;
    warn "\tReading $filename ...\n";
    open (FILE,$filename) or die "Can't open $filename";
    my @lines = <FILE>;
    close(FILE);
    my %hash; my $i; my $id; my @fields;
    foreach $line (@lines) {
	chomp($line);
	($id, @fields) = split(/$delim/,$line);
	$i = 0;
	foreach (@fields) {
	    $hash{$id}[$i] = $_;
	    $i++;
	}
    }
    return %hash;
}

1;
