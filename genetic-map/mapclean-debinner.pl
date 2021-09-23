#!/usr/bin/perl
use strict;

my $bins = $ARGV[0];
my $map = $ARGV[1];

my $hmap;
my $href;

open(MAP, $map);
my $lg;
while(<MAP>){
    chomp;
    my @a = split(/\s+/,$_);
    if ($a[1] =~ /lg/){
        $lg = $a[1];
 #   } elsif ($a[0] =~ /Contig/i || $a[0] =~ /scaf/i){
    } elsif ($a[0] =~ /utg/){
        $hmap->{$a[0]}->{'lg'} = $lg;
        $hmap->{$a[0]}->{'pos'} = $a[1];
    }
}
close MAP;

open(BIN, $bins);
while(<BIN>){
    chomp;
    my @a = split(/;/,$_);
    if (defined $hmap->{$a[0]}){
        my $link = $hmap->{$a[0]}->{'lg'};
        my $dist = $hmap->{$a[0]}->{'pos'};
        for (my $i = 1;$i < scalar(@a);$i++){
            $a[$i] =~ s/$/-B/;
            $hmap->{$a[$i]}->{'lg'} = $link;
            $hmap->{$a[$i]}->{'pos'} = $dist;
        }
    }
}

close BIN;

foreach my $key (keys %$hmap){
    print $key."\t".$hmap->{$key}->{'lg'}."\t".$hmap->{$key}->{'pos'}."\n";
}
