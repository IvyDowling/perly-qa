use WordNet::QueryData;
my $wn = WordNet::QueryData->new( noload => 1);
my $q = $ARGV[$#ARGV];

print "Synset: ", join(", ", $wn->querySense("$q#n#1", "syns")), "\n";
print "Similar to: ", join(", ", $wn->querySense("$q#n#1", "sim")), "\n";
print "Pertains to: ", join(", ", $wn->queryWord("$q#n#1", "part")), "\n";
print "Hypernym: ", join(", ", $wn->querySense("$q#n#1", "hype")), "\n";
print "derived: ", join(", ", $wn->queryWord("$q#n#1", "deri")), "\n";
print "POS: ", join(", ", $wn->querySense($q)), "\n";
print "Senses: ", join(", ", $wn->querySense($q)), "\n";
print "Forms: ", join(", ", $wn->validForms($q)), "\n";
print "Antonyms: ", join(", ", $wn->queryWord("$q#n#1", "ants")), "\n";
