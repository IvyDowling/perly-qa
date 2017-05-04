#!/usr/bin/perl -w
#Michael Dowling V00624504
#Natural Language Processing project 6
## RUN:
#	perl qa-system.pl mylogfile.txt
# This will then provide an opening script, and the user can input a question.
# The question must begin with (WHO | WHAT | WHEN | WHERE)
# then the system will decode the query and parse it to a wikipedia q
## SAMPLE:
# 	When was George Washington born? (user)
# 	George Washington was born on February 22, 1732. (system)
# todo a wiki search : $entry = $wiki->search( 'Perl' );
# perl-wiki api: http://search.cpan.org/~bricas/WWW-Wikipedia-2.01/lib/WWW/Wikipedia.pm
# This is the revised version of proj5,
# this project implements improvements on our previous system
# 	"In PA 6 you should enhance the functionality of your QA system in three ways :
# 		at least two enhancements to query reformulation,
#		at least two enhancements to answer composition,
#		Your system should decide between multiple candidate answers
#		based on a confidence score you compute."
## QUERY:
#	1. POS Tagging with WordNet.
#	2. All-Length-Grams by moving backwards through the 'good' input tokens.
## COMPOSITION:
#	1. Adjective synonyms using WordNet Similarity.
#	2.
## CONFIDENCE:
#	DOCUMENTS
#		1. Whole trimmed input--------Primary-----0.9
#		2. NOUNS from POS tagging-----Secondary---0.5
#		3. all-grams------------------Other-------0.2
#	SEARCH TERMS
#		1. Rearranged Orginal String--Primary-----0.9
#		2. Grams----------------------Secondary---0.7
#		3. Generated Values-----------Other-------0.4
use WWW::Wikipedia;
use WordNet::QueryData;
use Data::Dumper;
binmode STDOUT, ":utf8";
# little hash of stop words
my %stop_words = ("the" => 1, "a" => 1, "an" => 1, "did" => 1,
"of" => 1, "and" => 1, "on" => 1, "in" => 1,
"by" => 1, "with" => 1, "at" => 1, "after" => 1,
"into" => 1, "their" => 1, "is" => 1,
"that" => 1, "they" => 1, "for" => 1,
"to" => 1, "it" => 1, "them" => 1, "was" => 1, "which" => 1,
"who" => 1,"what" => 1,"when" => 1,"where" => 1);

my $wn = WordNet::QueryData->new( noload => 1);

print "Hi there, this is version 2 of the Q/A system by Michael Dowling!\n";
print "I'll try and answer any questions you have that start with\nWho, What, When, or Where. Enter 'exit' to leave the program.\n";
my $wiki = WWW::Wikipedia->new();
my ($logfilename) = @ARGV;
open(my $log, '>', $logfilename) or die "Could not open file $logfilename $!";
while(<STDIN>){
	chomp $_;
	# LOG #
	print $log "INPUT -> " . $_ . "\n";
	if($_ eq "exit") { # BYE
    	print "So long!\n";
		close $log;
		exit 1;
    } else {
		#
		# PARSE THE INPUT Q
		#
		my @queries;
		my @tokens = ($_=~/([^\s]+)[\s]*/g);
		# one of the first IMPROVEMENTS is to use WordNet
		# to improve our query construction
		# WordNet POS: 	$wn->querySense($q));
		my $q_word = lc $tokens[0]; # who
		my $tense_helper = $tokens[1]; # was
		my @nouns;
		my @adj;
		my @subj;
		for my $t (@tokens){
			# dont include stop words
			$lt = lc $t;
			if(!$stop_words{$lt}){
				push @subj, $lt;
				# IMPROVEMENT 1, WORD NET POS
				my @senses = $wn->querySense($lt);
				#print Dumper \@senses;
				# we want to primarily use adj for POS, so lets be greedy
				my $compress = join(';', @senses);
				if($compress=~/$lt#a/){
					push (@adj, $lt);
				} elsif($compress=~/$lt#n/){
					push (@nouns, $lt);
				}
			}
		}
		#print Dumper \@subj;
		#
		# QUERY CONSTRUCTION
		#
			# --RANK--
			#	1. Whole trimmed input--------Primary-----0.9
			#	2. NOUNS from POS tagging-----Secondary---0.5
			#	3. all-grams------------------Other-------0.2
		my $Primary = "";
		for my $s (@subj){
			$Primary .= " " . $s;
		}
		$Primary =~ s/^\s+|\s+$//g;
		# Tagged Nouns
		my $Secondary = "";
		for my $n (@nouns){
			$Secondary .= " " . $n;
		}
		$Secondary =~ s/^\s+|\s+$//g;
		# Another IMPROVEMENT here,
		# since these input queries are going to be small,
		# lets get every length n grams
		my @Other;
		for (my $i = scalar @subj; $i >= 0; $i = $i - 1) {
			# get all-grams
			if ($i != 0){
				my $j = $i - 1;
				my @helper;
				while ($j >= 0){
					push @helper, $subj[$j];
					# construct string from helper
					my $temp = "";
					for my $h (@helper){
						$temp = $h . " " . $temp;
					}
					$temp =~ s/^\s+|\s+$//g;
					push @Other, $temp;
					$j = $j - 1;
				}
			}
		}
		#print "PRIMARY: $Primary\n";
		#print "SECONDARY: $Secondary\n";
		#print Dumper \@Other;
		# LOG #
		print $log "QUERY -> ";
		print $log "$Primary\n";
		print $log "$Secondary\n";
		print $log Dumper \@Other;
		print $log "\n";
		# END LOG #
		my $P_Document = "";
		my $S_Document = "";
		my $O_Documents = "";
		# PRIMARY
		my $ret_p = $wiki->search($Primary);
		if ($ret_p && $ret_p ne ""){
			$P_Document = $ret_p->fulltext();
		}
		# SECONDARY
		my $ret_s = $wiki->search($Secondary);
		if ($ret_s && $ret_s ne ""){
			$S_Document = $ret_s->fulltext();
		}
		# OTHER
		for $o (@Other){
			my $ret = $wiki->search($o);
			if ($ret && $ret ne ""){
				$O_Documents .= "\n" . $ret->fulltext();
			}
		}
		# Pre-LOG #
		if(0){
		print $log "RETURN -> " . $P_Document . "\n";
		print $log $S_Document . "\n";
		print $log $O_Document . "\n";
		}
		# Lets replace newlines with spaces
		$P_Document =~ s/\n/ /g;
		$S_Document =~ s/\n/ /g;
		$O_Documents =~ s/\n/ /g;
		# so many xml tags, die die die
		$P_Document =~ s/<ref.+?\/ref>//g;
		$S_Document =~ s/<ref.+?\/ref>//g;
		$O_Documents =~ s/<ref.+?\/ref>//g;
		# Replace strange characters with  " "
		$P_Document =~ s/[^a-zA-Z\d\s\$\.\?\!\'\,]/ /g;
		$S_Document =~ s/[^a-zA-Z\d\s\$\.\?\!\'\,]/ /g;
		$O_Documents =~ s/[^a-zA-Z\d\s\$\.\?\!\'\,]/ /g;
		# Make all multi " " into one \s
		$P_Document =~ s/[\s]+/ /g;
		$S_Document =~ s/[\s]+/ /g;
		$O_Documents =~ s/[\s]+/ /g;
		$P_Document = lc $P_Document;
		$S_Document = lc $S_Document;
		$O_Documents = lc $O_Documents;
		# LOG #
		if(0){
		print $log "MASSAGED RETURN -> " . $P_Document . "\n";
		print $log $S_Document . "\n";
		print $log $O_Document . "\n";
		}
		# END LOG #
		## CONFIDENCE: (refresher)
		#	DOCUMENTS
		#		1. Whole trimmed input--------Primary-----0.9
		#		2. NOUNS from POS tagging-----Secondary---0.5
		#		3. all-grams------------------Other-------0.2
		#	SEARCH TERMS
		#		1. Rearranged Orginal String--Primary-----0.9
		#		2. Grams----------------------Secondary---0.7
		#		3. Generated Values-----------Other-------0.4

		#
		# SEARCH TERM CONSTRUCTION
		#
		my $s_original = "";
		# here we get to use our tense helper
		# from the beginning, as well as any adj we picked up
		# $Secondary from above is the collected nouns,
		$s_original = $Secondary .  " " . $tense_helper;
		if ($adj[0]){
			$s_original .= " " . $adj[0];
		}
		# this is the all-gram breakdown of the input,
		# same algorithm as above for all-gram construction
		# but we're using our s_original string, so lets split that into an arr
		my @s_orig_arr = split / /, $s_original;
		my @s_grams;
		for (my $i = scalar @s_orig_arr; $i >= 0; $i = $i - 1) {
			# get all-grams
			if ($i != 0){
				my $j = $i - 1;
				my @helper;
				while ($j >= 0){
					push @helper, $s_orig_arr[$j];
					# construct string from helper
					my $temp = "";
					for my $h (@helper){
						$temp = $h . " " . $temp;
					}
					$temp =~ s/^\s+|\s+$//g;
					# Had a lot of ussues with this process
					# creating the unigram for the stop word
					# so lets not let that happen again...
					if(!$stop_words{$temp}){
						push @s_grams, $temp;
					}
					$j = $j - 1;
				}
			}
		}
		# IMPROVEMENTS
		# Using wn similarity and synonyms
		my @generated;
		if (@adj){
			for my $a (@adj){
				# lets use the wordnet similarity value from qsense
				# 	ADJ-SIM		$wn->querySense("$q#a#1", "sim")
				#	synset		$wn->querySense("$q#a#1", "syns"));
				# pray for sense 1
				# we've got to pull off the word[#a#1] end bits
				my @sim_adj = $wn->querySense("$a#a#1", "sim");
				for my $gen (@sim_adj){
					push @generated, $gen =~ /([\w]+)#a#\d/g;
				}
				my @syn_adj = $wn->querySense("$a#a#1", "syns");
				for my $gen (@syn_adj){
					push @generated, $gen =~ /([\w]+)#a#\d/g;
				}
			}
		}
		if ($q_word eq "where"){
			push @generated, "located";
			my @sim_adj = $wn->querySense("located#a#1", "sim");
			for my $gen (@sim_adj){
				push @generated, $gen =~ /([\w]+)#a#\d/g;
			}
			my @syn_adj = $wn->querySense("located#a#1", "syns");
			for my $gen (@syn_adj){
				push @generated, $gen =~ /([\w]+)#a#\d/g;
			}
		} elsif ($q_word eq "when"){
			# here I'd like to do some sort of wn
			# check to decide which of these terms to use, but...
			push @keyword_terms, "started";
			push @keyword_terms, "ended";
			push @keyword_terms, "was born";
			push @keyword_terms, "died";
		}
		# LOG #
		print $log "SEARCH TERMS -> " . $s_original . "\n";
		print $log  Dumper \@s_grams;
		print $log "\n";
		print $log  Dumper \@generated;
		print $log "\n";
		# END LOG #
		# Collection phase
		# check each doc, then each search section.
		# $s_original 	-> 0.9
		# @s_grams		-> 0.7
		# @generated	-> 0.4
		my @dec_list;
		if ($P_Document){
			my $doc_w = 0.9;
			# These search terms will be used to
			# grab a sentence from the doc we're working in
			my $srch_w = 0.9;
			my @ret1 = ($P_Document =~ /.([\w\s\d]*$s_original[\w\s\d]*)\./g);
			if (@ret1){
				push @dec_list, [($doc_w * $srch_w), @ret1];
			}
			for my $g (@s_grams){
				$srch_w = 0.7;
				my @ret2 = ($P_Document =~ /.([\w\s\d]*$g[\w\s\d]*)\./g);
				if (@ret2){
					push @dec_list, [($doc_w * $srch_w), @ret2];
				}
			}
			for my $g (@generated){
				$srch_w = 0.4;
				my @ret3 = ($P_Document =~ /.([\w\s\d]*$g[\w\s\d]*)\./g);
				if (@ret3){
					push @dec_list, [($doc_w * $srch_w), @ret3];
				}
			}
		}
		if ($S_Document){
			my $doc_w = 0.5;
			my $srch_w = 0.9;
			my @ret1 = ($S_Document =~ /.([\w\s\d]*$s_original[\w\s\d]*)\./g);
			if (@ret1){
				push @dec_list, [($doc_w * $srch_w), @ret1];
			}
			for my $g (@s_grams){
				$srch_w = 0.7;
				my @ret2 = ($S_Document =~ /.([\w\s\d]*$g[\w\s\d]*)\./g);
				if (@ret2){
					push @dec_list, [($doc_w * $srch_w), @ret2];
				}
			}
			for my $g (@generated){
				$srch_w = 0.4;
				my @ret3 = ($S_Document =~ /.([\w\s\d]*$g[\w\s\d]*)\./g);
				if (@ret3){
					push @dec_list, [($doc_w * $srch_w), @ret3];
				}
			}
		}
		if ($O_Document){
			my $doc_w = 0.2;
			my $srch_w = 0.9;
			my @ret1 = ($O_Document =~ /.([\w\s\d]*$s_original[\w\s\d]*)\./g);
			if (@ret1){
				push @dec_list, [($doc_w * $srch_w), @ret1];
			}
			for my $g (@s_grams){
				$srch_w = 0.7;
				my @ret2 = ($O_Document =~ /.([\w\s\d]*$g[\w\s\d]*)\./g);
				if (@ret2){
					push @dec_list, [($doc_w * $srch_w), @ret2];
				}
			}
			for my $g (@generated){
				$srch_w = 0.4;
				my @ret3 = ($O_Document =~ /.([\w\s\d]*$g[\w\s\d]*)\./g);
				if (@ret3){
					push @dec_list, [($doc_w * $srch_w), @ret3];
				}
			}
		}
		# Now get all the higest confidence
		# one of the highest will be the top result,
		# but there may be many with the same confidence
		my @final_subset;
		my $metric = ${$dec_list[0]}[0];
		for my $c (@dec_list){
			my @cast = @{$c};
			if($cast[0] eq $metric){
				shift @cast;
				push @final_subset, @cast;
			}
		}
		# Last metric is frequency of words in each line
		# from our values from the search terms
		print $log Dumper \@final_subset;
		print Dumper \@final_subset;
	}
}
