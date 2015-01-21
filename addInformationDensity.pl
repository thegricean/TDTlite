#!/usr/bin/perl

use lib $ENV{TDTlite};
require "format.pl";
require "resources.pl";

my $version = "v.21";

# example call: perl addNgrams.pl -c swbd stringvar positionvar n shift_position
# perl addNgrams.pl -oc swbd TOP_string Len_position 2 1

########## has to be changed to make it flexible
my $n = shift(@ARGV);
if ($n > 3) { $n = 3; }             # at most trigrams

my %triGRAM;		            # hash for jointprobs
my %biGRAM;		            # hash for jointprobs
my %uniGRAM;
my $ngram_delim = getNgramDelim();

printVersionHeader("addInformationDensity $version");
if ($help) { printHelp("addInformationDensity"); }
elsif ($corpus eq "" || $NUM_factornames < 1) { printAbort(); }
else {
    my %cases = parseFactorHash();

    # input factors
    my $factor_name = $factornames[0];
    my $FIDstring = getFactorID($factor_name, %cases); 

    my @count_valuefound;
    my @count_valueknotfound;
    my @count_valuennotfound;
    my @count_excludedByPosition;
    my @count_excludedByDiscounting;
    my @count_excludedByZeroCount;
    my @count_includedByBackoff;

    # getting ngram hashs from ngram files
    if ($n == 3) { %triGRAM = getNgrams($corpus, 3); }
    %biGRAM = getNgrams($corpus, 2);
    %uniGRAM = getNgrams($corpus, 1);

    my $factor_info = "Information_".$factor_name."_".$n."gram";
    %cases = createFactor($factor_info, %cases);
    $FIDinfo = getFactorID($factor_info, %cases);
    
    my $factor_length = "Length_".$factor_name."_".$n."gram";
    %cases = createFactor($factor_length, %cases);
    $FIDlength = getFactorID($factor_length, %cases);


    foreach $id (keys %cases) {
	if ($id eq getHeaderID() || $id eq "") { next; }
	my $sentence = stripForNgrams($corpus, $cases{$id}[$FIDstring]);

# print "$n\t$sentence\n";
	if ($sentence eq "") { next; }
	my @words = split(/\s/, $sentence);
	
	$cases{$id}[$FIDlength] = $#words + 1;
# print "\t$#words\n";	
	my $information = info(1, $words[0], "");
	for ($position= 1; $position <= $#words; $position++) { 
	    my $ngramstring = "";				# reset for each type
	    my $kgramstring = "";				# reset for each type
	    
	    for ($i= $position - ($n - 1); $i < $position - 1; $i++) {
		if ($i < 0) { next; }
		$ngramstring .= $words[$i].$ngram_delim;
		$kgramstring .= $words[$i].$ngram_delim;
	    }
	    if ($position - 1 >= 0) { 
		$ngramstring .= $words[$position - 1].$ngram_delim.$words[$position];
		$kgramstring .= $words[$position - 1];
	    }
	    $information+= info(min($n, $position + 1), $ngramstring, $kgramstring);
	}
	$cases{$id}[$FIDinfo] = $information;
    }
    writeFactorHash(%cases);
}
printFooter();


############################# subs #####################################

sub removePenultimateElement {
    my ($oldstring) = @_;

    my @words = split($ngram_delim, $oldstring);
    my $newstring = "";

    foreach ($i= 0; $i < $#words - 1; $i++) {   
        $newstring .= $words[$i].$ngram_delim;
    }
    return $newstring.$words[$#words];
}

sub removeUltimateElement {
    my ($oldstring) = @_;

    my @words = split($ngram_delim, $oldstring);
    my $newstring = "";

    foreach ($i= 0; $i < $#words - 1; $i++) {
        $newstring .= $words[$i].$ngram_delim;
    }
    return $newstring.$words[$#words - 1];
}

sub info {
    my ($n, $ngramstring, $kgramstring) = @_;
    my $backoff= 0; 

# print "\tOriginal strings:\n\t\t$ngramstring\n\t\t$kgramstring\n";    
    if ($n == 3) {
	$jfqn = $triGRAM{ $ngramstring};
	$jfqk = $biGRAM{ $kgramstring};
	if ($jfqn eq "" || $jfqk eq "") {
	    $backoff= 1;
	    $n= 2;
	    $ngramstring= backoff($ngramstring);
	    $kgramstring= backoff($kgramstring);
	}
    }
    if ($n == 2) {
        $jfqn = $biGRAM{ $ngramstring};
        $jfqk = $uniGRAM{ $kgramstring};
        if ($jfqn eq "" || $jfqk eq "") {              
            $backoff= 1;
            $n= 1;
            $ngramstring= backoff($ngramstring);
	    $kgramstring= "";
        }
    }
    if ($n == 1) {
        $jfqn = $uniGRAM{$ngramstring};
	$jfqk = $uniGRAM{getTotalWordCountKey()}; 
    }

# print "\tFinal strings:\n\t\t$ngramstring\n\t\t$kgramstring\n";
# print "\t\tJFQn: $jfqn\n\t\tJFQk: $jfqk\n";
    if ($jfqn > 1 && $jfqk > 1) { 
	$cndp = ($jfqn - 1)  / ($jfqk - 1);
	if ($backoff == 1) { $count_includedByBackoff[$t]++;}
# print "\t\t\tSmoothed probability: $cndp\n";	
	return -log($cndp) / log(2); 
    }
    else {
# print "\t\t\tSmoothed probability: LOW\n";
	return -log(1 / $uniGRAM{getTotalWordCountKey()}) / log(2);  
    }
}

sub backoff {
    my ($string) = @_;
    
    my ($first, @rest) = split($ngram_delim, $string);
    return join($ngram_delim, @rest);
}

sub min {
    if ($_[0]>$_[1]) {return $_[1]} else {return $_[0]};
}


 
