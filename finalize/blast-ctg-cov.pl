#!/usr/bin/perl
use strict;

my $contigs = $ARGV[0];
my $blasthits = $ARGV[1];

my $hctg;

#prefilter for identity/length/etc before here.

open(FH, $contigs);
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

open(FH, $blasthits);
# m8 format
# telomere        utg122607       100.00  35      0       0       1       35      141     107     5e-11   69.9
while(<FH>){
    chomp;
    my @a = split(/\s+/, $_);
    my $start;
    my $end;
    if ($a[8] < $a[9]){
        $start = $a[8];
        $end = $a[9];
    } else {
        $start = $a[9];
        $end = $a[8];
    }
#fill it in
    for (my $i = $start; $i <=$end ; $i++){ 
        $hctg->{$a[1]}->{'found'} = 1;
        $hctg->{$a[1]}->{'pos'}->{$i} = 1;
    }
}

foreach my $key(keys %$hctg){
    if ($hctg->{$key}->{'found'} == 1){
        my $seqlength = length($hctg->{$key}->{'seq'});
        my $hitlen = 0;
        foreach my $posfound(keys %{$hctg->{$key}->{'pos'}}){
            $hitlen++;
        }
        my $rounded = sprintf("%.5f", ($hitlen/$seqlength));
        print "$key\t$seqlength\t$hitlen\t$rounded\n";
    }
}
