#!/usr/bin/perl
use strict;
my $href;

#>utg33651 1 121882
#>utg303232 2 95109
#>utg88743 3 5


while(<STDIN>){
    chomp;
    if ($_ =~ /^>/){
        #import utg list
        my @a=split(/\s+/,$_);
        $a[0] =~ s/>//;
        $href->{$a[1]} = $a[0];
    } else {
        #make tour from utg
        my @a = split(/\s+/,$_);
        print ">REVIEW-TOUR\n";
        foreach my $utg(@a){
            if($utg =~ /^\-/){
                $utg =~ s/^.//;
                print $href->{$utg}."- ";
            } else {
                print $href->{$utg}."+ ";
            }
        }
        print "\n";
    }
}
