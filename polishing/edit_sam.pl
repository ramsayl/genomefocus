#!/usr/bin/perl;
use strict;

while(<STDIN>){
 if ($_ =~ /^@/){
    print $_
 } else {
    my $line1 = $_;
    my $line2 = <STDIN>;
    $line1 =~ s/\t/:1:N:0:320\t/;
    $line2 =~ s/\t/:2:N:0:320\t/;
    print $line1;
    print $line2;
  }
}
