#!/usr/bin/perl

use lib $ENV{TDT};
require "format.pl";
require "resources.pl";

my $version = "v.43";

printVersionHeader("AddTerminalTimeInfo $version");
if ($help) { printHelp("addTerminalTimeInfo"); }
elsif ($corpus eq "" || $num_newfactors) { printAbort(); }
else {
    my %cases = parseFactorHash();
    
    foreach $factor (@factornames) {
	# ID of variable in the output file (i.e. column)
	my $fid = getFactorID($factor, %cases);
	print "Factor ID for factor '$factor': $fid\n\n";
	
	######################
	# creating new factors
	######################
	my $factorDur = $factor . "_duration";  
	%cases = createFactor($factorDur, %cases);
	my $fidDur = getFactorID($factorDur, %cases);
	
	my $factorSyl = $factor . "_syllables";
	%cases = createFactor($factorSyl, %cases);
	my $fidSyl = getFactorID($factorSyl, %cases);
	
	my $factorPauseB = $factor . "_precedingPause";  
	%cases = createFactor($factorPauseB, %cases);
	my $fidPauseB = getFactorID($factorPauseB, %cases);
	
	my $factorPauseA = $factor . "_followingPause";  
	%cases = createFactor($factorPauseA, %cases);
	my $fidPauseA = getFactorID($factorPauseA, %cases);
	
	my $factorSpIndex = $factor . "_spWindow";
	%cases = createFactor($factorSpIndex, %cases);
	my $fidSpIndex = getFactorID($factorSpIndex, %cases);

	my $factorSpSylIndex = $factor . "_spWindowSyllablePosition";
	%cases = createFactor($factorSpSylIndex, %cases);
	my $fidSpSylIndex = getFactorID($factorSpSylIndex, %cases);
	
	my $factorSpSyl = $factor . "_spWindowSyllables";
	%cases = createFactor($factorSpSyl, %cases);
	my $fidSpSyl = getFactorID($factorSpSyl, %cases);
	
	my $factorSpDur = $factor . "_spWindowSyllableDuration";  
	%cases = createFactor($factorSpDur, %cases);
	my $fidSpDur = getFactorID($factorSpDur, %cases);
	
	my $factorSpTotal = $factor . "_spWindowTotalDuration";
	%cases = createFactor($factorSpTotal, %cases);
	my $fidSpTotal = getFactorID($factorSpTotal, %cases);
	
	my $factorBreak = $factor . "_BreakIndex";
	%cases = createFactor($factorBreak, %cases);
	my $fidBreak = getFactorID($factorBreak, %cases);
	
	my $factorPhraseTone = $factor . "_PhraseTone";
	%cases = createFactor($factorPhraseTone, %cases);
	my $fidPhraseTone = getFactorID($factorPhraseTone, %cases);
	
	my $factorBoundaryTone = $factor . "_BoundaryTone";
	%cases = createFactor($factorBoundaryTone, %cases);
	my $fidBoundaryTone = getFactorID($factorBoundaryTone, %cases);
	
	my $factorAccentStrength = $factor . "_AccentStrength";
	%cases = createFactor($factorAccentStrength, %cases);
	my $fidAccentStrength = getFactorID($factorAccentStrength, %cases);

	my $factorAccentType = $factor . "_AccentType";
	%cases = createFactor($factorAccentType, %cases);
	my $fidAccentType = getFactorID($factorAccentType, %cases);

	# can run out memory here!
	# switch this back on to load all time info at once (costs memory)
#	my %words = getWordTimeInfoLines();

	my $TAG_dur = "phonwordDuration";
	my $TAG_syl = "phonwordSyllables";
	my $TAG_precPause = "phonwordPrecedingPause";
	my $TAG_follPause = "phonwordFollowingPause";
	my $TAG_spIndex = "spWindow";
	my $TAG_spSylIndex = "spWindowSyllablePosition";
	my $TAG_spSylDur = "spWindowSyllableDuration";
	my $TAG_spSyl= "spWindowSyllables";
	my $TAG_spTotalDur = "spWindowTotalDuration";
	my $TAG_breakIndex = "prosPhraseIndex";
	my $TAG_phraseTone = "prosPhraseTone";
	my $TAG_boundaryTone = "prosPhraseBoundaryTone";
	my $TAG_accentStrength = "prosAccentStrength";
	my $TAG_accentType = "prosAccentType";
	
	my $missing = 0;
	my $empty = 0;
	my $illegals = 0;
	my %words;
	my $oldconversation = 0;
	foreach $id (sort sortTGrep2ID keys %cases) {
	    if ($cases{$id}[$fid] eq $factor) { next; }
	    elsif ($cases{$id}[$fid] =~ /((sw\d+)_s\d+_\d+)/) {
		my $xmlid = $1;
		my $conversation = $2;
	        if ($oldconversation ne $conversation) { %words = getWordTimeInfo($conversation); }
		$oldconversation = $conversation;

		if ($words{$xmlid} =~ /$TAG_dur=\"([^\"]+)\".+$TAG_syl=\"([^\"]+)\".+$TAG_precPause=\"([^\"]+)\".+$TAG_follPause=\"([^\"]+)\"/) {
		    $cases{$id}[$fidDur] = $1;
		    $cases{$id}[$fidSyl] = $2;
		    $cases{$id}[$fidPauseB] = $3;
		    $cases{$id}[$fidPauseA] = $4;
		    
		    if ($words{$xmlid} =~ /$TAG_spIndex=\"([^\"]+)\".+$TAG_spSylIndex=\"([^\"]+)\".+$TAG_spSyl=\"([^\"]+)\".+$TAG_spSylDur=\"([^\"]+)\".+$TAG_spTotalDur=\"([^\"]+)\"/) {
			$cases{$id}[$fidSpIndex] = $1;
			$cases{$id}[$fidSpSylIndex] = $2;
			$cases{$id}[$fidSpSyl] = $3;
			$cases{$id}[$fidSpDur] = $4;
			$cases{$id}[$fidSpTotal] = $5;
		    }
		    if ($words{$xmlid} =~ /$TAG_breakIndex=\"([^\"]+)\"/) { $cases{$id}[$fidBreak] = $1; }
		    if ($words{$xmlid} =~ /$TAG_phraseTone=\"([^\"]+)\"/) { $cases{$id}[$fidPhraseTone] = $1; }
		    if ($words{$xmlid} =~ /$TAG_boundaryTone=\"([^\"]+)\"/) { $cases{$id}[$fidBoundaryTone] =$1; }
		    if ($words{$xmlid} =~ /$TAG_accentStrength=\"([^\"]+)\"/) { $cases{$id}[$fidAccentStrength] =$1; }
		    if ($words{$xmlid} =~ /$TAG_accentType=\"([^\"]+)\"/) { $cases{$id}[$fidAccentType] =$1; }
		}
		else { 
		    if ($warnings) { warn formatWarning("No duration information found for xml ID $xmlid"); }
		    $missing++;
		}
	    }
	    else { 
		if ($cases{$id}[$fid] eq "") {
		    $empty++;
		    if ($warning) { warn "Factor $factor for $id has empty xml ID value.\n"; }
		}
		else { 
		    print "Factor $factor for $id is not in right format: $cases{$id}[$fid]\n"; 
		    $illegals++; 
		}
	    }
	}
	if ($missing > 0) { printLine("No duration information found for ${missing} cases (see -w for more detail)."); }
	print "NB: Due to annotation inconsistencies in the current XML version, there may be missing speechrate and prosodic information.\n";
	if ($empty > 0) { printLine("There were $empty cells with empty xml ID values."); }
	if ($illegals > 0) { printLine("There were $illegals cells with invalid xml IDs."); }
	printLine();
    }
    writeFactorHash(%cases);
}
printFooter();

