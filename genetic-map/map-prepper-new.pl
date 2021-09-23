#!/usr/bin/perl
use strict;

my $vcf = $ARGV[0];
my $base = $vcf;
$base =~ s/\.vcf//;
system("vcftools --vcf $vcf --out $base --remove-indels --maf 0.25 --max-maf 0.75 --min-alleles 2 --max-alleles 2 --max-missing 0.95 --minQ 30 --recode");
system("cat $base.recode.vcf|perl parse_vcf.pl > $base.recode.parsed");
##also make a header to tack on
##CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	HI.4457.006.BioOHT_16.LR-11-33-best-sorted-rmdup.bam
system("grep CHROM $vcf|sed 's/\tID//'|sed 's/\tREF//'|sed 's/\tALT//'|sed 's/\tQUAL//'|sed 's/\tFILTER//'|sed 's/\tINFO//'|sed 's/\tFORMAT//'>header.txt");
system("mapclean-AB-ize.pl $base.recode.parsed 4 5 > $base.recode.parsed.AB"); #NEW SED
system("cat header.txt $base.recode.parsed.AB > $base.recode.parsed.AB.h");
system("mapclean-binner.pl $base.recode.parsed.AB.h > $base.recode.parsed.AB.h.binned 2>$base.recode.parsed.AB.h.key");
#remove parents
#get data and make the headers for mstmap

open(FH, "$base.recode.parsed.AB.h.binned");
my $head = <FH>;
$head =~ s/Seqposition\t#CHROM\tPOS\t\S+\t\S+\t//;
my $next = <FH>;
my @firstline = split(/\s+/, $next);
my $ind = (scalar(@firstline)-3); # 3 because 1-parents
my @lines = <FH>;
my $loci = (scalar(@lines)+1);
close FH;
open(FH, "$base.recode.parsed.AB.h.binned");
open(OUT, ">$base.recode.parsed.AB.h.binned.np");
my $header = <FH>;
while(<FH>){
$_ =~ s/Seqposition\t#CHROM\tPOS\t\w+\t\w+\t//;
    my @line=split(/\t/,$_);
    splice(@line, 1, 2);
    my $fin = join("\t", @line);
    $fin =~ s/\t\t/\t/; $fin =~ s/\t\t/\t/;
    print OUT $fin;
}
close FH;
close OUT;

#set missing threshold different - can adjust as needed
my @pvals = ("0.0000001", "0.00000001","0.000000001","0.0000000001","0.00000000001");
foreach my $p (@pvals){
    open(OUTFILE, ">$base.$p.head");
    print OUTFILE "population_type F2
population_name $base
distance_function kosambi
cut_off_p_value $p
no_map_dist 15
no_map_size 0
missing_threshold 0.1
estimation_before_clustering no
detect_bad_data yes
objective_function COUNT
number_of_loci $loci
number_of_individual $ind

Seqpos\t$head
";
    close OUTFILE;
    system("cat $base.$p.head $base.recode.parsed.AB.h.binned.np |grep -v CHROM >$base.$p.new.mstin");
#    system("/isilon/users/larissa/programs/MSTmap/MSTMap/MSTMap.exe $base.$p.mstin $base.$p.mstout >$base.$p.mstlog 2>$base.$p.mstlog");
}
