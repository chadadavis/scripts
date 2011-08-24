#!/usr/bin/env perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $in = new Bio::SeqIO(-fh => \*ARGV, 
                        -format=>'Fasta');

# Also try 'desc'
my $attr = shift || 'display_id';

while (my $seq = $in->next_seq) {
    my ($label) = split ' ', $seq->$attr();
    print STDERR $label, "\n";
    my $out = new Bio::SeqIO(-file => ">${label}.fa",
                             -format=>'Fasta');
    $out->write_seq($seq);
    
}


