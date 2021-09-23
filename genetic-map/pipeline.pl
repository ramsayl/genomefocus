#!/usr/bin/perl
use strict;

#This script intended to be run on one lane worth of samples at a time. 
#Columns in the samplelist file are:
#	Read1name	Read2name	Finaloutputfilebasename


my $samplelist = $ARGV[0];
my $samplelog  = $ARGV[1];

#DEFINE
# Edit as necessary for reference fasta, bowtie index, threads.
my $reffa = ""
my $bowtie2index = "";
my $lanetotalreads = 0;
my $lanetotalsamples = 0;
my $threads = 40;

# run fastQC before everything else
open(FH, $samplelist);
while(<FH>){
    chomp;
    my @reads = split(/\t/,$_);
    if (scalar(@reads) != 3){
        die "Incorrect number of columns in row $lanetotalsamples: has ".scalar(@reads)."!\n";
    }
    system("../bin/FastQC/fastqc -q -t 60 -nogroup -l custom-limits.txt $reads[0]");
    system("../bin/FastQC/fastqc -q -t 60 -nogroup -l custom-limits.txt $reads[1]");
    my $qcr1 = $reads[0];
    my $qcr2 = $reads[1];
    $qcr1 =~ s/\.fastq\.gz/_fastqc.html/;
    $qcr2 =~ s/\.fastq\.gz/_fastqc.html/;
    open(QC1, $qcr1);
    open(SLOG, "+>>$samplelog");
    while(<QC1>){
        if ($_ =~ /Total Sequences<\/td><td>(\d+)/){
             print SLOG "$reads[0] Total sequences $1\n";
             $lanetotalreads += $1;
             $lanetotalsamples++;
        }
        if ($_ =~ /WARN/) { print SLOG "$reads[0] QC WARN\n" }
        if ($_ =~ /FAIL/) {
            print SLOG "$reads[0] QC FAILED!\n";
            close SLOG;
            close QC1;
            warn  "QC failed on samples $reads[0]";
        }
    }
    close QC1;
    open(QC2, $qcr2);
    while(<QC2>){
        if ($_ =~ /WARN/) { print SLOG "$reads[1] QC WARN\n" }
        if ($_ =~ /FAIL/) {
            print SLOG "$reads[1] QC FAILED!\n";
            close SLOG;
            close QC2;
            warn "QC failed on samples $reads[1]";
        }
    }
    close QC2;
    close SLOG;
}
close FH;

#If a sample is under plex level +-10% of lane report
open(SLOG, "+>>$samplelog");
if ($lanetotalsamples > 1){
    my $tenp = $lanetotalreads/10;
    my $plexdiv = $lanetotalreads/$lanetotalsamples;
    while(<SLOG>){
        if ($_ =~ /(.*) Total sequences (\d+)/){
            my $read = $1;
            if ($2 < ($plexdiv-$tenp) || $2 > ($plexdiv+$tenp)){
                print SLOG "$read read count warning: under/over by 10%\n";
            }
        }
    }
} else {
    print SLOG "$lanetotalsamples samples in processed set.\n";
}
close SLOG;

open(FH, $samplelist);
while(<FH>){
    chomp;
    my @reads = split(/\t/,$_);
# too lazy to open/close file, just append
    system("echo '\nProcessing $reads[0] and $reads[1] for sample base name $reads[2]...\n'>>$samplelog");
# for each sample, trim
    my $pe1out = $reads[0];
    my $pe2out = $reads[1];
    my $up1out = $reads[0];
    my $up2out = $reads[1];
    $pe1out =~ s/\.gz/-p.gz/g;
    $pe2out =~ s/\.gz/-p.gz/g;
    $up1out =~ s/\.gz/-s.gz/g;
    $up2out =~ s/\.gz/-s.gz/g;
 
    system("java -jar trimmomatic-0.36.jar PE -threads 30 -phred33 $reads[0] $reads[1] $pe1out $up1out $pe2out $up2out ILLUMINACLIP:all-truseq.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:30 MINLEN:50 >> $samplelog 2>> $samplelog");

# align with bowtie2, filter for unique reads, remove duplicates, create bam, call variants (raw)
    my $sambase = $reads[2];
    system("bowtie2 --end-to-end -k 3 --no-mixed --no-discordant --no-sq --no-head -p $threads -X 500 -R 5 -x $bowtie2index -1 $pe1out -2 $pe2out -S $sambase.sam >> $samplelog 2>>$samplelog");
    system("bwt2-besthits.pl $sambase.sam $sambase-best.sam >>$samplelog 2>>$samplelog");
    system("samtools view -bT $reffa $sambase-best.sam > $sambase-best.bam 2>>$samplelog");
    system("samtools sort -m 100G -o $sambase-best-sorted.bam -O bam $sambase-best.bam >>$samplelog; 2>>$samplelog");
    system("samtools rmdup $sambase-best-sorted.bam $sambase-best-sorted-rmdup.bam >rmdup.log 2>>rmdup.log");
    system("samtools index $sambase-best-sorted-rmdup.bam");
    system("samtools mpileup -B -g -m 10 -t ADF,ADR,DP -d 1000 -f $reffa -o $sambase.bcf $sambase-best-sorted-rmdup.bam");
# Raw variant calls only, no standard filtering implemented at this time
#    system("/isilon/users/larissa/programs/bcftools-1.3.1/bcftools call -A -m -v $sambase.bcf >$sambase.vcf &");
# cleanup to reduce disk space used
   system("rm $sambase-best.bam $sambase-best-sorted.bam");
   system("rm *-p.gz");
   system("rm *-s.gz");
# additional command for stats etc go here.

}


