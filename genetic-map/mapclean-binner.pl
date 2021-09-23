#!/usr/bin/perl
use strict;

#This asumes you have cleaned the data into parent A and B and have a one line header.

my $file = $ARGV[0];
my $href;


# INPUT

open(FH, $file);
my $header = <FH>;
# header cleanup
chomp $header;
$header =~ s/^\w+\t\w+\t//;
$header =~ s/\s+$//;
my @lines = split(/\s+/, $header);

while(<FH>){
    chomp;
    my @arr = split(/\s+/,$_);
    splice @arr, 2, 2; # remove ref/alt cols
    # file needs to have scaff/unique id in col 0, position in col 1
    #janky counting for line name coherency
    my $endofline = (scalar(@lines)+2);
    for (my $i = 2;$i < $endofline;$i++){
        my $c = $i-2;
        $href->{$arr[0]}->{$arr[1]}->{@lines[$c]} = $arr[$i];
        # ie, href->{"scaffold101"}->{"135378"}->{"RIL101"} = "A";
    }
}

# PROCESSING: Fill in missing data points.

foreach my $scaffold(keys %$href){
    foreach my $snppos(keys %{$href->{$scaffold}}){
        foreach my $line(keys %{$href->{$scaffold}->{$snppos}}){
            if ($href->{$scaffold}->{$snppos}->{$line} eq "-"){
                #iterate through pos in the scaff again to search for closest defined markers
                my $distup;
                my $distdown;
                foreach my $calcpos(keys %{$href->{$scaffold}}){
                    if ($calcpos > $snppos){
                        if (!defined $distup && $href->{$scaffold}->{$calcpos}->{$line} ne "-"){
                            $distup = ($calcpos-$snppos);
                        } elsif (($snppos - $calcpos) < $distup && $href->{$scaffold}->{$calcpos}->{$line} ne "-"){
                            $distup = ($calcpos-$snppos);
                        }
                    }
                    if ($calcpos < $snppos){
                        if (!defined $distdown && $href->{$scaffold}->{$calcpos}->{$line} ne "-"){
                            $distdown = ($snppos-$calcpos);
                         } elsif (($snppos - $calcpos) < $distdown && $href->{$scaffold}->{$calcpos}->{$line} ne "-"){
                             $distdown = ($snppos-$calcpos);
                         }
                    }
                }

                #flanking call on both sides
                my $countup = $snppos+$distup;
                my $countdown = $snppos-$distdown;
                if (defined $distup && defined $distdown){
                    if ($href->{$scaffold}->{$countup}->{$line} eq $href->{$scaffold}->{$countdown}->{$line}){
                        $href->{$scaffold}->{$snppos}->{$line} = $href->{$scaffold}->{$countup}->{$line};
                    }
                }
                #flanking call on one side, end of scaffold -- not elsif on above because might remove or change approach later
                # edit: might as well call it the snp above/below for binning purposes
                if (!defined $distup && defined $distdown){
                    $href->{$scaffold}->{$snppos}->{$line} = $href->{$scaffold}->{$countdown}->{$line};
                    #print STDERR "Inferred missing data at scaffold $scaffold line $line\n";
                } elsif (defined $distup && !defined $distdown){
                    $href->{$scaffold}->{$snppos}->{$line} = $href->{$scaffold}->{$countup}->{$line};
                    #print STDERR "Inferred missing data at scaffold $scaffold line $line (end of scaffold)\n";
                } else {
                    #print STDERR "Can't fix missing data at scaffold $scaffold line $line\n";
                }
            }
        }
    }
}
    
# OUTPUT

# Print header
print "Seqposition";
foreach my $linename(@lines){
    print "\t$linename";
}
print "\n";

# Print revised scaffolds -- output is unsorted, please sort afterwards if desired -- map prog won't care.

my $segseen;

foreach my $scaffold(keys %$href){
    foreach my $snppos(keys %{$href->{$scaffold}}){
        my $segline;
        foreach my $linename(@lines){
           $segline .=  "\t".$href->{$scaffold}->{$snppos}->{$linename};
        }
        if (defined $segseen->{$segline}){
           $segseen->{$segline} .= ";".$scaffold."p".$snppos;
        } else {
            $segseen->{$segline} = $scaffold."p".$snppos;
        }
    }
}


foreach my $key(keys %$segseen){
   my @snps = split(/;/, $segseen->{$key});
   print STDERR $segseen->{$key}."\n";
   print $snps[0].$key."\n";
}
