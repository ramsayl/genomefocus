#!/usr/bin/perl -w

use strict;

my $sam_file = $ARGV[0] || die "Usage\n";
my $out_file = $ARGV[1] || die "Usage\n";


#HWI-ST822:1:43932 419 scaffold_130    793763  255 101M    =   794398  730 CTATAATTT   *   AS:i:-11    XN:i:0  XM:i:2  XO:i:0  XG:i:0  NM:i:2  MD:Z:58T34C7    YT:Z:CP XR:Z:@HWI-ST822%3A161%3AD0ULDA


open(SAM,"<".$sam_file) || die "Cannot open sam file\n";
open(OUT,">".$out_file) || die "Cannot write out file\n";

my %data;
my $cons = 18;
while(<SAM>) {
    chomp;
    if ($_ =~ /^@/) {
        print OUT $_."\n";
    }
    else {
        my ($id1,$bw_flag1,$s1,$s_s1,$mapq1,$maps1,$ja1,$p_s1,$size1,$seq1,$jb1,$aln_score1,@junks1) = (split("\t",$_));
        $aln_score1=~s/AS:i://g;
        next if $s1 eq '*';
        my $l1 = $_."\n";
        my $l2 = <SAM>;

        my ($id2,$bw_flag2,$s2,$s_s2,$mapq2,$maps2,$ja2,$p_s2,$size2,$seq2,$jb2,$aln_score2,@junks2) = (split("\t",$l2));
        $aln_score2=~s/AS:i://g;

        die "Unexpected file format\n" unless ($id1 eq $id2 && $s1 eq $s2 && $s_s1 eq $p_s2 && $p_s1 eq $s_s2);
        if (exists($data{$id1})) {
            if( $data{$id1}->{score} <= ($aln_score1 + $aln_score2+$cons)) {
                $data{$id1}->{num_best}+=1;
            }
        }
        else {
            $data{$id1} = {l1=>$l1, l2=>$l2,num_best=>1,score=>$aln_score1+$aln_score2};
        }
        

    }
}
my $num_uniq_hits =0;
my $num_multi_hits=0;

foreach my $id (keys %data) {
    if ($data{$id}->{num_best} eq 1) {
        $num_uniq_hits++;
        print OUT $data{$id}->{l1}.$data{$id}->{l2};
    }
    else {
        $num_multi_hits++;
    }
}

warn "Found $num_uniq_hits number of uniquely mapped reads in $sam_file\n";
warn "Found $num_multi_hits number of multi-mapped reads in $sam_file\n";
warn "There is a total of ".($num_uniq_hits+$num_multi_hits)." hits\n";

