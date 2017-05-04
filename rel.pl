#!/usr/bin/perl

use WordNet::QueryData;
use WordNet::Similarity::lesk;
use WordNet::Similarity::vector;
my $qd = WordNet::QueryData->new();
my $wnlesk = WordNet::Similarity::lesk->new($qd);
my $wnvector = WordNet::Similarity::vector->new($qd);
my ($a, $b) = @ARGV;
chomp $a;
chomp $b;
my $leskscore = $wnlesk->getRelatedness("$a#v#1", "$b#v#1");
my $vectorscore = $wnvector->getRelatedness("$a#v#1", "$b#v#1");
print "lesk = $leskscore\n";
print "vector = $vectorscore\n";
