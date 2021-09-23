#!/usr/bin/perl
use strict;

my $file = $ARGV[0];
my $pacol = $ARGV[1];
my $pbcol = $ARGV[2];

#assumes first 4 cols are scaf, pos, ref, alt

open(FH, $file);
while(<FH>){
    chomp;
    my $line = $_;
    my @arr = split(/\t/,$_);
    my $refref = $arr[2].$arr[2];
    my $altalt = $arr[3].$arr[3];
    my $refalt = $arr[2].$arr[3];
    #verify they're diff
    if ($arr[$pacol] ne $arr[$pbcol]){
     if($arr[$pacol] ne "X" || $arr[$pbcol] ne "X"){
        #nohets
        if ($arr[$pacol] ne "$refalt" && $arr[$pbcol] ne "$refalt"){
            if ($arr[$pacol] eq $refref){
                $line =~ s/$refref/A/g;
                $line =~ s/$altalt/B/g;
                $line =~ s/DIS/X/g;
                $line =~ s/$refalt/X/g;
                print $line."\n";
            } elsif ($arr[$pbcol] eq $refref){
                $line =~ s/$refref/B/g;
                $line =~ s/$altalt/A/g;
                $line =~ s/DIS/X/g;
                $line =~ s/$refalt/X/g;
                print $line."\n";
            } elsif ($arr[$pbcol] eq $altalt){
                $line =~ s/$refref/A/g;
                $line =~ s/$altalt/B/g;
                $line =~ s/DIS/X/g;
                $line =~ s/$refalt/X/g;
                print $line."\n";
            } elsif ($arr[$pacol] eq $refref){
                $line =~ s/$refref/B/g;
                $line =~ s/$altalt/A/g;
                $line =~ s/DIS/X/g;
                $line =~ s/$refalt/X/g;
                print $line."\n";
            }
        }
      }
    }
}
