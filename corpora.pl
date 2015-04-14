#!/usr/bin/perl

sub getCorpusFile {
    my ($corpus,$corpusdir) = @_;
#	print "$corpus\n";
#	print "$corpusdir\n";
    my %corpusfiles = ('swbd' => 'swbd.t2c.gz',
		       'swbdext' => 'sw.backtrans_011410.t2c.gz',	
                       'bnc' => 'bnc-charniak-parses.t2c.gz',
                       'arab' => 'arabic-collapsed.t2c.gz',
                       'wsj' => 'wsj_mrg.t2c.gz',
                       'brown' => 'brown.t2c.gz',
                       'chin' => 'chtb5.1.t2c',
                       'ice' => 'icegb.t2c.gz',
                       'negra' => 'negra.t2c.gz',
                       'tiger' => 'tiger.t2c.gz',
                       'ycoe' => 'ycoe.t2c.gz');

    return $corpusdir.$corpusfiles{$corpus};
    #return $corpdir.$corpfile;
}

1;
