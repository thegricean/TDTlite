#!/usr/bin/perl

use lib $ENV{TDT};
require "format.pl";
require "resources.pl";

my $version = "v.59";
my $corpus = shift(@ARGV);
my $file = shift(@ARGV);
my $space = " ";
my $POS_DELIM = getPOSDelim();
my $EOS = getEOS();

# Starting with version 0.58, split.pl prepares\n";
# ngram-files in such a way that bleeding between\n";
# sentences is prevented.";

if (!$noversion) { printVersionHeader("Split $version"); }
if (!$file) {
    while (<>) {
	printwords(stripForNgrams($corpus, $_));
    }
} else {
    open(F1, $file) || die "Could not open file $file: $!\n";
    while (<F1>) {
	printwords(stripForNgrams($corpus, $_));
    }
}


sub printwords {
    my ($line) = @_;

    my @words = split($space, $line);
    foreach $w (@words) { 
	# added for version >= 0.5
	# deal with part of speech (POS) tags
	if ($corpus eq "swbd") {
	    $w = removeNITEID($w);            # delete XML-tag after POS
	}
	$w =~ s/^$POS_DELIM.*$//g;              # delete lines w/ empty string    

	# print the word if it is not zero and if it's not the case that a period
	# has been seen just before and now again (happens due to the way speaker 
	# and turn information is encoded in e.g. the switchboard).
	if ($w ne "" && !($w =~ /^$EOS$/ && $previousw =~ /^$EOS$/)) {
	    $previousw = $w;

	    my ($term, $pos) = split($POS_DELIM, $w);
	    if ($pos eq "") { print lc($term)."\n"; }                
	    else { print lc($term).$POS_DELIM.uc($pos)."\n"; }
	    
            # prevent bleeding between sentences
	    # to undo this, simply remove this statement
	    if ($w =~ /^$EOS$/) {
		if ($pos eq "") { print lc($term)."\n".lc($term)."\n"; }    
		else { print lc($term).$POS_DELIM.uc($pos)."\n".lc($term).$POS_DELIM.uc($pos)."\n"; }    
	    }
	}
    }
}

