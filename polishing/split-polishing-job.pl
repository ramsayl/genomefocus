#!/usr/bin/perl
use strict;

my $reffalist = $ARGV[0]; # just plain list of fasta entries, no prefix ">"
my $sam = $ARGV[1];
my $fqin = $ARGV[2];
my $samout = $ARGV[3];
my $fqout = $ARGV[4];

my $href;
my $fqhref;

open(FH,$reffalist); 
while (<FH>){
    chomp;
    $href->{$_} = 0;
}
close FH;

open(SAM, $sam);
open(FQOUT, ">$fqout");
open(SAMOUT, ">$samout");
while(<SAM>){
# 0 is the read, 2 is the utg
    my @a=split(/\t/,$_);
    if (defined ($href->{$a[2]})){
        print SAMOUT $_;
        #record the read
        $fqhref->{$a[0]} = 0;
    }
}
close SAMOUT;

open(FQOUT, ">$fqout");
open(FH, $fqin);
while(<FH>){
    my @a = split(/\t+/,$_);
    my @id = split(/\s+/,$a[0]);
    $id[0] =~ s/^@//;
    my $line = $_;
    my $seq = <FH>;
    my $qq = <FH>;
    my $qual = <FH>;
    if (defined $fqhref->{$id[0]}){
        print FQOUT $line.$seq.$qq.$qual;
    }
}

close FQOUT;

