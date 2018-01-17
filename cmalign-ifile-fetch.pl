#!/usr/bin/env perl
# 
# cmalign-ifile-fetch.pl: Given a ifile or elfile output by cmalign (--ifile or --elfile) 
#                         
#
# EPN, Mon May  8 08:41:36 2017
# 

use strict;
use warnings;
use Getopt::Long;

my $in_tblout  = "";   # name of input tblout file

my $usage;
$usage  = "cmalign-ifile-fetchl v0.01 [Jan 2018]\n\n";
$usage .= "Usage:\n\n";
$usage .= "cat <1 or more cmalign --ifile or --elfile files> | cmsearch-ifile-fetch.pl [OPTIONS]\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-n <n>       : set minimum sized insert to fetch to <n> [default: 20]\n";

my $n      = 20;    # minimum size insert to fetch
my $n_opt  = undef; # -n arg, if used

&GetOptions( "n=s" => \$n_opt);

if(defined $n_opt) { 
  $n = $n_opt;
}

  ######################################################################
  # Example file:
  ######################################################################
  ## Insert information file created by cmalign.
  ## This file includes 2+<nseq> non-'#' pre-fixed lines per model used for alignment,
  ## where <nseq> is the number of sequences in the target file.
  ## The first non-'#' prefixed line per model includes 2 tokens, separated by a single space (' '):
  ## The first token is the model name and the second is the consensus length of the model (<clen>).
  ## The following <nseq> lines include (4+3*<n>) whitespace delimited tokens per line.
  ## The format for these <nseq> lines is:
  ##   <seqname> <seqlen> <spos> <epos> <c_1> <u_1> <i_1> <c_2> <u_2> <i_2> .... <c_x> <u_x> <i_x> .... <c_n> <u_n> <i_n>
  ##   indicating <seqname> has >= 1 inserted residues after <n> different consensus positions,
  ##   <seqname> is the name of the sequence
  ##   <seqlen>  is the unaligned length of the sequence
  ##   <spos>    is the first (5'-most) consensus position filled by a nongap for this sequence (-1 if 0 nongap consensus posns)
  ##   <epos>    is the final (3'-most) consensus position filled by a nongap for this sequence (-1 if 0 nongap consensus posns)
  ##   <c_x> is a consensus position (between 0 and <clen>; if 0: inserts before 1st consensus posn)
  ##   <u_x> is the *unaligned* position (b/t 1 and <seqlen>) in <seqname> of the first inserted residue after <c_x>.
  ##   <i_x> is the number of inserted residues after position <c_x> for <seqname>.
  ## Lines for sequences with 0 inserted residues will include only <seqname> <seqlen> <spos> <epos>.
  ## The final non-'#' prefixed line per model includes only '//', indicating the end of info for a model.
  ##
  #SSU_rRNA_eukarya 1851
  #KJ759662.1 1799 1 1847  243 240 2  1045 1027 1
  #AY674584.1 1692 56 1789  75 21 1  243 186 3  284 230 1  1745 1645 1  1749 1650 3
  #AJ428101.1 1752 21 1819  72 53 1  243 221 2  1456 1389 1  1745 1675 1  1749 1680 3
  #AF412790.1 1752 35 1816  180 146 2  228 193 12  243 208 9  267 241 2  503 479 1  1111 1077 1  1740 1673 1  1749 1683 3
  #AY745557.1 1845 32 1793  127 96 1  180 150 2  228 199 17  267 255 2  503 493 1  651 642 1  737 722 34  799 818 1  815 835 1  870 891 2  1396 1419 32  1740 1789 1  1749 1799 4  1764 1814 3
  #LT631038.1 1826 1 1848  127 116 5  189 183 8  458 440 1  495 478 4  737 710 22  799 794 2  846 843 9  1099 1105 4  1111 1121 2  1446 1431 5  1558 1546 3
  #KC673609.1 1742 1 1816  72 73 1  180 180 1  841 799 1  1749 1675 1
  #KJ616757.1 1794 5 1849  72 69 1  243 234 1  1745 1689 1  1765 1710 1
  #KC487934.1 1651 48 1748  228 178 1  237 187 1  243 194 2
  #//

my $nfetched = 0;
my $nskipped = 0;
my ($modelname, $modellen, $seqname, $seqlen, $spos, $epos, $rfpos, $seqpos, $ilen) = 
    (undef, undef, undef, undef, undef, undef, undef, undef, undef);
while(my $line = <>) { 
  chomp $line;
  # 2 types of lines to distinguish
  # type 1: 2 tokens <model-name> <model-consensus-length>
  # type 2: sequence line: 4+3*<n> tokens
  if($line !~ /^\#/) { 
    my @el_A = split(/\s+/, $line);
    my $nel = scalar(@el_A);
    if($nel == 2) { 
      if($line =~ /^(\S+)\s+(\d+)/) { 
        ($modelname, $modellen) = ($1, $2); # neither of these values are actually used, currently
      }
      else { 
        die "ERROR line has two tokens but is in wrong format: $line";
      }
    }
    elsif($nel >= 4) { 
      ($seqname, $seqlen, $spos, $epos) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3]);
      for(my $i = 4; $i < $nel; $i += 3) { 
        ($rfpos, $seqpos, $ilen) = ($el_A[$i], $el_A[($i+1)], $el_A[($i+2)]);
        if($ilen >= $n) { 
          printf("%s/%d-%d %d %d %s\n", $seqname, $seqpos, $seqpos+$ilen-1, $seqpos, $seqpos+$ilen-1, $seqname);
          $nfetched++;
        }
        else { 
          $nskipped++;
        }
      }
    }
  }
}
