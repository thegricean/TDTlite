#!/usr/bin/perl

use lib $ENV{TDT};
require "format.pl";
require "resources.pl";

my $version = "v.65";

# CONSTANTS
my $file_mappings = getConversationFile();
my $sp_id= "Speaker_ID";
my $sp_sex="Speaker_sex";
my $sp_bd="Speaker_birthdate";
my $sp_dia="Speaker_dialect";
my $sp_edu="Speaker_education";
my $sp_pay="Speaker_payment";
my $sp_AB="Speaker_AB";
my $sic="TURNinCONV";
my $tic="TOPinCONV";
my $conv_id="Conversation_ID";
my $conv_topicid="Conversation_topic_ID";
my $conv_topic="Conversation_topic";
my $conv_difficulty="Conversation_transcription-difficulty";
my $conv_topicality="Conversation_topic-variability";
my $conv_naturalness="Conversation_naturalness";

my $larg = @ARGV;								# number of remaining arguments

printVersionHeader("AddConversationInformation $version");
if ($help) { printHelp("addConversationInfo"); }
elsif ($corpus ne "swbd") { warn "FATAL ERROR: Speaker information is only available for Switchboard (swbd)!\n"; printAbort(); }
else {
    my %fid;
    my %cases = parseFactorHash();
    %cases = createFactor($sp_id, %cases);
    $fid{$sp_id} = getFactorID($sp_id, %cases);
    %cases = createFactor($sp_sex, %cases);
    $fid{$sp_sex} = getFactorID($sp_sex, %cases);
    %cases = createFactor($sp_bd, %cases);
    $fid{$sp_bd} = getFactorID($sp_bd, %cases);
    %cases = createFactor($sp_dia, %cases);
    $fid{$sp_dia} = getFactorID($sp_dia, %cases);
    %cases = createFactor($sp_edu, %cases);
    $fid{$sp_edu} = getFactorID($sp_edu, %cases);
    %cases = createFactor($sp_pay, %cases);
    $fid{$sp_pay} = getFactorID($sp_pay, %cases);
    %cases = createFactor($sic, %cases);
    $fid{$sic} = getFactorID($sic, %cases);
    %cases = createFactor($tic, %cases);
    $fid{$tic} = getFactorID($tic, %cases);
    %cases = createFactor($sp_AB, %cases);
    $fid{$sp_AB} = getFactorID($sp_AB, %cases);
    %cases = createFactor($conv_id, %cases);
    $fid{$conv_id} = getFactorID($conv_id, %cases);
    %cases = createFactor($conv_topicid, %cases);
    $fid{$conv_topicid} = getFactorID($conv_topicid, %cases);
    %cases = createFactor($conv_topic, %cases);
    $fid{$conv_topic} = getFactorID($conv_topic, %cases);
    %cases = createFactor($conv_difficulty, %cases);
    $fid{$conv_difficulty} = getFactorID($conv_difficulty, %cases);
    %cases = createFactor($conv_topicality, %cases);
    $fid{$conv_topicality} = getFactorID($conv_topicality, %cases);
    %cases = createFactor($conv_naturalness, %cases);
    $fid{$conv_naturalness} = getFactorID($conv_naturalness, %cases);
    
    print "Reading in node-speaker-conversation mappings ...\n";
    my %mappings = parseFactorHash($file_mappings);
    $mfid{$sp_id} = getFactorID($sp_id, %mappings);
    $mfid{$sp_sex} = getFactorID($sp_sex, %mappings);
    $mfid{$sp_bd} = getFactorID($sp_bd, %mappings);
    $mfid{$sp_dia} = getFactorID($sp_dia, %mappings);
    $mfid{$sp_edu} = getFactorID($sp_edu, %mappings);
    $mfid{$sp_pay} = getFactorID($sp_pay, %mappings);
    $mfid{$sic} = getFactorID($sic, %mappings);
    $mfid{$tic} = getFactorID($tic, %mappings);
    $mfid{$sp_AB} = getFactorID($sp_AB, %mappings);
    $mfid{$conv_id} = getFactorID($conv_id, %mappings);
    $mfid{$conv_topicid} = getFactorID($conv_topicid, %mappings);
    $mfid{$conv_topic} = getFactorID($conv_topic, %mappings);
    $mfid{$conv_difficulty} = getFactorID($conv_difficulty, %mappings);
    $mfid{$conv_topicality} = getFactorID($conv_topicality, %mappings);
    $mfid{$conv_naturalness} = getFactorID($conv_naturalness, %mappings);
    
    
    print "\nGathering information about speakers and conversations...\n";
    foreach $id (keys %cases) {
	if ($id eq getHeaderID()) { next;}
	$id =~ /^(\d+):\d+/ or die "Error in input file formatting\n";
	my $k = $1;
	my $lookupid= $k .":1";
	
	
	until($mappings{$lookupid}[$sp_id] ne "") {			# go backwards in conversation until you find a speakerID
	    $k--;
	    $lookupid= $k .":1";
	}
	if ($warnings && ($cases{$id}[$fid{$sp_id}] ne emptyValue()) && $cases{$id}[$fid{$sp_id}] ne $mappings{$lookupid}[$mfid{$sp_id}]) { warn "\t\tWARNING: Multiple speaker IDs for item $id (last one taken)\n"; }
	$cases{$id}[$fid{$sp_id}] = $mappings{$lookupid}[$mfid{$sp_id}];
	$cases{$id}[$fid{$sp_sex}] = $mappings{$lookupid}[$mfid{$sp_sex}];
	$cases{$id}[$fid{$sp_bd}] = $mappings{$lookupid}[$mfid{$sp_bd}];
	$cases{$id}[$fid{$sp_dia}] = $mappings{$lookupid}[$mfid{$sp_dia}];
	$cases{$id}[$fid{$sp_edu}] = $mappings{$lookupid}[$mfid{$sp_edu}];
	$cases{$id}[$fid{$sp_pay}] = $mappings{$lookupid}[$mfid{$sp_pay}];
	$cases{$id}[$fid{$sp_AB}] = $mappings{$lookupid}[$mfid{$sp_AB}];
	$cases{$id}[$fid{$sic}] = $mappings{$lookupid}[$mfid{$sic}];
	$cases{$id}[$fid{$tic}] = $mappings{$lookupid}[$mfid{$tic}];
	if ($warnings && $cases{$id}[$fid{$conv_id}] ne emptyValue() && $cases{$id}[$fid{$conv_id}] ne $mappings{$lookupid}[$mfid{$conv_id}]) { warn "\t\tWARNING: Multiple conversation IDs for item $id (last one taken)\n"; }
	$cases{$id}[$fid{$conv_id}] = $mappings{$lookupid}[$mfid{$conv_id}];
	$cases{$id}[$fid{$conv_topicid}] = $mappings{$lookupid}[$mfid{$conv_topicid}];
	$cases{$id}[$fid{$conv_topic}] = $mappings{$lookupid}[$mfid{$conv_topic}];
	$cases{$id}[$fid{$conv_difficulty}] = $mappings{$lookupid}[$mfid{$conv_difficulty}];
	$cases{$id}[$fid{$conv_topicality}] = $mappings{$lookupid}[$mfid{$conv_topicality}];
	$cases{$id}[$fid{$conv_naturalness}] = $mappings{$lookupid}[$mfid{$conv_naturalness}];
    }
    print "Information collected.\n\n";

    writeFactorHash(%cases);
}
printFooter();
