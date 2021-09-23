#!/usr/bin/perl
use strict;

my $file = $ARGV[0];
my $refseqs;
my $newrefseqs;
my $id;

open(FH, $file);
while(<FH>){
  chomp;
  if ($_ =~ /^>(.*)/ ) {
    $id = $1;
  } else {
    $refseqs->{$id} .= $_;
  }
}

#>utg127661 117 521443
#>utg1525:::fragment_1 118 2575781
#>utg1525:::fragment_2:::debris 119 125000
#>utg1525:::fragment_3 120 1783028
#>utg16756 121 655911
#>utg147785 122 1051012
#>utg165357 123 151631
#>utg77436:::fragment_1 124 670057
#>utg77436:::fragment_2:::debris 125 25000
#>utg77436:::fragment_3 126 715000
#>utg77436:::fragment_4:::debris 127 25000
#>utg77436:::fragment_5 128 2218418

#splits specified contigs into 3 parts: A, B, C
#contig	pos1	pos2
while(<STDIN>){
  chomp;
  
  my @a=split(/\s/,$_);
  my $seq = $refseqs->{$a[0]};
  my $frag = $a[1];
  my $seqa = substr($seq, 0, $a[2]);
  $refseqs->{$a[0]} = "";
  $refseqs->{"$a[0]_$frag"} = $seqa;
  $refseqs->{$a[0]} = substr($seq, ($a[2])); 
}

foreach my $key (keys %$refseqs){
  my $seq = $refseqs->{$key};
  my $l = length($seq);
  if($l >1){
    print ">$key\n";
    for(my $i=0;$i <=$l;$i+=60){
      print substr $seq, $i, 60;
      print "\n";
    }
  }
}
  
