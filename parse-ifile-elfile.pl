$usage = "perl parse-ifile-elfile.pl <ifile> <elfile> <min to print>";

if(scalar(@ARGV) != 3) { die $usage; };

my ($ifile, $elfile, $min2print) = (@ARGV);

open(IFILE, $ifile) || die "ERROR unable to open $ifile";
open(ELFILE, $elfile) || die "ERROR unable to open $elfile";

while($line = <IFILE>) { 
  chomp $line;
  if($line !~ /^\#/) { 
    @el_A = split(/\s+/, $line);
    $nel = scalar(@el_A);
    ($name, $length, $spos, $epos) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3]);
    $output_str_H{$name} = sprintf("%-60s", $name);
    $i = 4;
    for($i = 4; $i < $nel; $i += 3) { 
      ($rfpos, $seqpos, $len) = ($el_A[$i], $el_A[($i+1)], $el_A[($i+2)]);
      if($len >= $min2print) { 
        $output_str_H{$name} .= " $rfpos:$len:I";
      }
    }
  }
}
close(IFILE);

while($line = <ELFILE>) { 
  chomp $line;
  if($line !~ /^\#/) { 
    @el_A = split(/\s+/, $line);
    $nel = scalar(@el_A);
    ($name, $length, $spos, $epos) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3]);
    $i = 4;
    for($i = 4; $i < $nel; $i += 3) { 
      ($rfpos, $seqpos, $len) = ($el_A[$i], $el_A[($i+1)], $el_A[($i+2)]);
      if($len >= $min2print) { 
        $output_str_H{$name} .= " $rfpos:$len:E";
      }
    }
  }
}
close(ELFILE);

foreach $name (sort keys %output_str_H) { 
  print $output_str_H{$name} . "\n";
}
