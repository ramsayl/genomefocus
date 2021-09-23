#!/usr/bin/perl
use strict;

# new prefix, final agp, contig fasta, assembly fasta, list of plastid or other scafs to remove

my ($prefix, $agp, $ctgfa, $asmfa, $plist) = @ARGV;
my $hctg;
my @removed;

#read in contigs
open(FH, $ctgfa);
my $id;
while(<FH>){
  chomp;
  if ($_ =~ /^>(.*)/ ) {
    my @temp = split(/\s+/,$1);
    $id = $temp[0];
  } else {
    $hctg->{$id}->{'seq'} .= $_;
  }
}
close FH;

#write removed scafs to file, delete from hash
open(FH, $plist);
open(WRITE, ">$prefix.removedcontigs.fa");
while(<FH>){
  chomp;
  my $name = $_;
  push(@removed, $name);
  my $seq = $hctg->{$name}->{'seq'};
  my $l = length($seq);
  if($l >1){
    print WRITE ">$name\n";
    for(my $i=0;$i <=$l;$i+=60){
      print WRITE substr $seq, $i, 60;
      print WRITE "\n";
    }
  }
  delete $hctg->{$name};
}
close FH;
close WRITE;

#sort by length and make new names
open(CTGAGP, ">$prefix.contigs.agp");
open(CTGFA, ">$prefix.contigs.fasta");
my $renum = 0;
foreach my $key (sort { length($hctg->{$b}->{'seq'}) <=> length($hctg->{$a}->{'seq'}) } keys %$hctg) {
  my $found = 0;
  foreach my $badctg(@removed){
     if ($badctg eq $key){
         $found = 1;
     }
  }
  if ($found == 0){
    $renum++;
    my $number = sprintf("%06d", $renum); 
    $hctg->{$key}->{'renum'} = $prefix.".unitig.".$number;

# write contig AGP for name relationship
    print CTGAGP $hctg->{$key}->{'renum'}."\t1\t".length($hctg->{$key}->{'seq'})."\t1\tW\t".$key."\t1\t".length($hctg->{$key}->{'seq'})."\t0\n";

# write contig fasta with new names
  if (defined $hctg->{$key}->{'renum'}){
    print CTGFA ">".$hctg->{$key}->{'renum'}."\n";
    my $seq = $hctg->{$key}->{'seq'};
    for(my $i=0;$i <=length($hctg->{$key}->{'seq'});$i+=60){
        print CTGFA substr $seq, $i, 60;
        print CTGFA "\n";
    }
  }
  }
}
close CTGAGP;
close CTGFA;

#read agp and replace names

open(AGP, ">$prefix.agp");
open(FH, $agp);
while(<FH>){
    chomp;
    my @line = split(/\s+/,$_);
    if ($_ =~ /utg/ && defined $hctg->{$line[5]}->{'renum'}){
        if ($line[5] =~ /utg/){
            my $name = $line[5];
            $line[5] = $hctg->{$name}->{'renum'};
        }
        if ($line[0] =~ /utg/){
            my $name = $line[0];
            $line[0] = $hctg->{$name}->{'renum'};
        }
        my $out = join("\t", @line);
        print AGP $out."\n";
    } elsif ($_ =~ /utg/ && !defined $hctg->{$line[5]}->{'renum'}){
        next;
    } else {
        print AGP $_."\n";
    }   
}
close FH;
close AGP;

#read assembly fasta and replace names
#for chr, fix those in advance manually.
open(ASM, ">$prefix.fasta");
open(FH, $asmfa);
my $id;
my $href;
while(<FH>){
  chomp;
  if ($_ =~ /^>(.*)/ ) {
    my @temp = split(/\s+/,$1);
    $id = $temp[0];
  } else {
    $href->{$id}->{'seq'} .= $_;
  }
}

#pretty print for lentil chr - again we assume the pseudomolecules have been properly renamed here
for (my $i = 1;$i <= 7;$i++){
    my $chrname = $prefix.".Chr$i";
    print ASM ">$chrname\n";
    my $seq = $href->{$chrname}->{'seq'};
    my $l = length($seq);
    if($l >1){
      for(my $i=0;$i <=$l;$i+=60){
        print ASM substr $seq, $i, 60;
        print ASM "\n";
      }
    }
}
#now the remaining contigs with proper names
foreach my $key (keys %$href){
  if (defined $hctg->{$key}->{'renum'}){
     print ASM ">".$hctg->{$key}->{'renum'}."\n";
     my $seq = $href->{$key}->{'seq'};
     my $l = length($seq);
     if($l >1){
       for(my $i=0;$i <=$l;$i+=60){
         print ASM substr $seq, $i, 60;
         print ASM "\n";
       }
     }
  }
  
}
close FH;
close ASM;


