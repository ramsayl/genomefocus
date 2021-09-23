# GenomeFocus
GenomeFocus long read genome assembly workflow for large and highly repetitive genomes

USAGE: Created based on our best assembly methods so far for highly homozygous legume genomes (lentil, pea). May not be suitable for other species.

DATA TYPES NEEDED:
* \>50x coverage long read data (Pacbio or Oxford Nanopore)
* \>10x short read data (Illumina shotgun)
* An existing dense genetic map or data to create one. The steps for our in-house workflow for linkage group creation with GBS or other short read data are shown here, but this step could be modified to use any existing map. It should be noted that this map is for creation of linkage groups only.
* HiC data. Workflow is set up for Arima libraries, but would presumably work with others if parameters were adjusted. Data required will depend on library quality -- suggest an ideal 20x or more "coverage" of the raw reads (pre-HiCUP processing)

## OVERVIEW

The overall workflow is visually described in the file 'workflow.png'. In summary, long reads are assembled with smartdenovo, and polished with racon. Due to the high degree of telomere tethering observed in these species, a genetic map is used to form the initial clusters for HiC data incorporation. The HiC is then used to order and orient contigs within each pseudomolecule cluster. Any corrections and a final manual check are made with Juicebox. 

## WORKFLOW DETAILS

### Preparation

It is recommended to move or symlink raw sequence files to the sequences subdirectory for organization purposes.

### 1: Initial Assembly
Necessary software: smartdenovo

In the assembly subdirectory, edit smartdenovo-k23.make for your raw sequence file and install of smartdenovo. We find this kmer and assembler best for lentil genomes -- however other assemblers may do better for other genomes (redbean, canu, etc).

A calculate_n50 perl script has been included to aid with assesment of raw read coverage and quality as well as draft assembly stats.
  
### 2: Polish Assembly

Necessary software: bwa, minimap2, racon, gmap, BUSCO

We run two rounds of racon polishing using long reads, followed by one of illumina shotgun sequencing, primarily to polish genic regions. Upcoming versions of the workflow will likely include medaka in this stage. As an assembly completeness check, we will run gmap to compare the CDS sequences from a related species to the polished assembly, as well as run BUSCO. Expect 92-96% completeness with the eudicotyledons_odb10 database.

Copy/link initial assembly to this directory, use minimap2 to align the long reads and run racon on the resulting SAM file. 
 
Sample:
```
  minimap2 -x map-ont -L -t 120 --secondary=no -a initial_assembly.fasta /sequences/raw-sequences.fa > minimap-racon-iter1k23map-ont.sam 2> minimap-racon-iter1k23map-ont.log
  racon -t 120 raw-sequences.fa minimap-racon-iter1k23map-ont.sam initial_assembly.fasta >racon-iter1.fasta 2>racon-iter1.err
  minimap2 -x map-ont -L -t 120 --secondary=no -a racon-iter1.fasta /sequences/raw-sequences.fa > minimap-racon-iter2k23map-ont.sam 2> minimap-racon-iter2k23map-ont.log
  racon -t 120 raw-sequences.fa minimap-racon-iter2k23map-ont.sam racon-iter1.fasta >racon-iter2.fasta 2>racon-iter2.err
```

Trim short read data. 
 In the case of short reads, map them in paired-end mode, but treat them as single-end to run in racon.
 NOTE: occasionally running racon on short read data will fail for no obvious reason. In that case, although less ideal, I suggest mapping reads as single-end and attempt to rerun racon with that mapping.
 
Sample:
```
bwa index racon-iter2.fasta
bwa mem racon-iter2.fasta -T 160 -t 96 -B 10 -U 0 -L 10 samples/S00E866_r1-p.fastq samples/S00E866_r2-p.fastq >iter1illumina-paired.sam 2>iter1illumina-paired.log
```

Edit the regexp in `edit_sam.pl` to correspond to your sequencing files, and create the files to run as if single-end in racon.
```
cat samples/S00E866_r1-p.fastq samples/S00E866_r2-p.fastq | perl -pne 'if($_ =~ /^@/){$_ =~ s/\s+/:/}' >samples/S00E866_r12-p-e.fastq
cat iter1illumina-paired.sam|perl edit_sam.pl >iter1illumina-paired-edit.sam
racon -t 140 samples/S00E866_r12-p-e.fastq iter1illumina-paired-edit.sam racon-iter2.fasta > racon-iter2i1.fasta 2> racon-iter2i1.log
```

The split-polishing-job.pl script allows you to split racon tasks into parts if RAM usage is an issue.. Since RAM usage is related to number of reads mapping more than the raw contig count, the best method to split up your data should be determined by your assembly. Create lists of contigs per part and run as so:
```
IG_72805/polishing/cmd-k23.sh:perl run.pl racon-iter1-part1.list minimap-racon-iter1k23map-ont.sam ../sequences/S00E866-guppy3.6.1.pass.fastq part1.sam part1.fastq &
IG_72805/polishing/cmd-k23.sh:perl run.pl racon-iter1-part2.list minimap-racon-iter1k23map-ont.sam ../sequences/S00E866-guppy3.6.1.pass.fastq part2.sam part2.fastq &
IG_72805/polishing/cmd-k23.sh:perl run.pl racon-iter1-part2.list minimap-racon-iter1k23map-ont.sam ../sequences/S00E866-guppy3.6.1.pass.fastq part3.sam part3.fastq &
```

### 3) Initial HiC Run

 Filter and align HiC data using HiCUP. Split potentially chimeric contigs with SALSA2. 

 programs: HiCUP and prerequisites, SALSA2, BEDtools
 
 Run HiCUP as described in its documentation (create bowtie2 index for polished contigs, run hicup_extractor, etc). One of its config files, prepared for bowtie2 alignment, is here, but requires insertion of various file names to run.
 Create a merged alignment of all relevant hicup.bam files. One will be created per lane of data.
 Samples:
 ```
 samtools merge merged.bam *hicup.bam &
samtools sort -n -@ 4 -o merged-sorted.bam merged.bam
```
 Commands to prepare appropriate input for SALSA2 are provided in the short run-salsa.cmd bash script.


### 4a) Genetic Map

 If no high-density genetic map exists, map short reads from sequencing of a RIL/DH population to the polished assembly contigs and generate a rough map including as many contigs in the linkage groups as possible. Ideally one of the parents will be the line assembled, due to structural variation observed in many populations. This map can also be used to identify potential chimeric sequences missed in the HiC data.

 Necessary software: FastQC, bowtie2, samtools, bcftools, vcftools, MSTMAP
 
 Create a bowtie2 index of split reads
 Create a config file for data -- the format is descibed in pipeline.pl. The script must be edited for reference fasta/index.
 ```
 perl pipeline.pl config log >log 2>log
 ```
 run mpileup on the population and create MSTMap input files. Some inferring of missing data is done here in the map prepping scripts as well as binning of 100% identical markers. Parameters on vcftools filtering may need to be adjusted depending on data quality. 
 
 Sample:
 ```
 samtools mpileup -B -g -m 10 -t ADF,ADR,DP -d 1000 -f assembly.cleaned.fasta -o LR-UNK.bcf parent1.bam parent2.bam ril1.bam ril2.bam ril3.bam
 mapprepper.pl LR-UNK.vcf
 ```
 
 MSTMap can be RAM intensive with many markers, so the various P-value input files generated are not run automatically. Adjust parameters until the linkage groups are reasonable. Run the `mapclean-debinner.pl` script to pull apart binned data and use the map to identify potential chimeras (contigs that appear in more than one linkage group).
 
Sample:
```
perl /isilon/users/larissa/programs/analysis-scripts/mapclean-debinner.pl LR-90*key LR-90.custom3.new.mstout|sort -k2,2 -k3,3n >LR-90.custom3.new.mstout.debinned
cat *debinned|sed 's/p/\t/'|sed 's/-B//'|sort -k3,3 -k4,4n|perl -ne 'if ($_ =~ /lg\d{1}\s+/){print $_}' >relevant-lg.debinned
```


### 4b) Second HiC Run
 
 Re-run HiC on the contigs split by SALSA2. Converting of coordinates from the original run should be possible if CPU time is limiting. 

 Necessary software: HiCUP and dependencies

### 5) ALLHiC Configuration, Rescue, and Optimize

 Use data from the genetic map linkage groups to initially group and create clusters file. A sample is provided to show the format. the initial number is the number of contigs in each group. Rescue contigs containing no markers in the map and optimize ordering of contigs within each cluster.
 
 Necessary software: ALLHiC

Sample:
```
grep lg0 relevant-lg.debinned |cut -f 1 |sort|uniq|wc -l
grep lg0 relevant-lg.debinned |cut -f 1 |sort|uniq|perl -ne 'chomp; print " $_"' >lg0
grep lg1 relevant-lg.debinned |cut -f 1 |sort|uniq|wc -l
grep lg1 relevant-lg.debinned |cut -f 1 |sort|uniq|perl -ne 'chomp; print " $_"' >lg1
grep lg16 relevant-lg.debinned |cut -f 1 |sort|uniq|wc -l
grep lg16 relevant-lg.debinned |cut -f 1 |sort|uniq|perl -ne 'chomp; print " $_"' >lg16
grep lg17 relevant-lg.debinned |cut -f 1 |sort|uniq|wc -l
grep lg17 relevant-lg.debinned |cut -f 1 |sort|uniq|perl -ne 'chomp; print " $_"' >lg17
grep lg4 relevant-lg.debinned |cut -f 1 |sort|uniq|wc -l
grep lg4 relevant-lg.debinned |cut -f 1 |sort|uniq|perl -ne 'chomp; print " $_"' >lg4
grep lg6 relevant-lg.debinned |cut -f 1 |sort|uniq|wc -l
grep lg6 relevant-lg.debinned |cut -f 1 |sort|uniq|perl -ne 'chomp; print " $_"' >lg6
grep lg7 relevant-lg.debinned |cut -f 1 |sort|uniq|wc -l
grep lg7 relevant-lg.debinned |cut -f 1 |sort|uniq|perl -ne 'chomp; print " $_"' >lg7
#manually edit in counts
cat lg* >clusters.txt

allhic extract --RE 'GATCGATC,GANTGATC,GANTANTC,GATCANTC' merged-sorted.bam assembly.cleaned.fasta

ALLHiC_rescue -b merged-sorted.bam -r assembly.cleaned.fasta -c clusters.txt -i ../allhic/merged-sorted.counts_GATCGATC_GANTGATC_GANTANTC_GATCANTC.txt >log 2>err

allhic optimize group1.txt merged-sorted.clm >log 2>err &
allhic optimize group2.txt merged-sorted.clm >log 2>err &
allhic optimize group3.txt merged-sorted.clm >log 2>err &
allhic optimize group4.txt merged-sorted.clm >log 2>err &
allhic optimize group5.txt merged-sorted.clm >log 2>err &
allhic optimize group6.txt merged-sorted.clm >log 2>err &
allhic optimize group7.txt merged-sorted.clm >log 2>err &

ALLHiC_build assembly.cleaned.fasta
```

### 6) Juicebox

Re-run HiC against the 'current' version of the assembly built with ALLHiC. Then create files to review and edit the assembly with Juicebox. The agp2assembly.py script can be obtained at https://github.com/phasegenomics/juicebox_scripts. The awk command to properly convert the sam file to a format useful for juicebox binary creation was obtained from a forum discussion. 

Necessary software: HiCUP, Juicebox and tools jar, MUMmer.

```
samtools merge merged.bam *hicup.bam &
samtools sort -n -@ 4 -o merged-sorted.bam merged.bam
samtools view merged-sorted.bam |awk 'BEGIN {FS="\t"; OFS="\t"} {name1=$1; str1=and($2,16); chr1=$3; pos1=$4; mapq1=$5; getline; name2=$1; str2=and($2,16); chr2=$3; pos2=$4; mapq2=$5; if(name1==name2) { if (chr1>chr2){print name1, str2, chr2, pos2,1, str1, chr1, pos1, 0, mapq2, mapq1} else {print name1, str1, chr1, pos1, 0, str2, chr2, pos2 ,1, mapq1, mapq2}}}' | sort -k3,3d -k7,7d > readnamesort.txt &

perl -e 'for($i=1;$i <=7;$i++){system("cat readnamesort.txt |perl -ne 'if ($_ =~ /group$i.*group$i/){print $_}' >g$i-readnamesort.txt");}'
//
cat readnamesort.txt |perl -ne 'if ($_ =~ /group1.*group1/){print $_}' >g1-readnamesort.txt &
cat readnamesort.txt |perl -ne 'if ($_ =~ /group2.*group2/){print $_}' >g2-readnamesort.txt &
cat readnamesort.txt |perl -ne 'if ($_ =~ /group3.*group3/){print $_}' >g3-readnamesort.txt &
cat readnamesort.txt |perl -ne 'if ($_ =~ /group4.*group4/){print $_}' >g4-readnamesort.txt &
cat readnamesort.txt |perl -ne 'if ($_ =~ /group5.*group5/){print $_}' >g5-readnamesort.txt &
cat readnamesort.txt |perl -ne 'if ($_ =~ /group6.*group6/){print $_}' >g6-readnamesort.txt &
cat readnamesort.txt |perl -ne 'if ($_ =~ /group7.*group7/){print $_}' >g7-readnamesort.txt &
//
perl -e 'for($i=1;$i <=7;$i++){system("grep ^group$i groups.agp|tail -1|cut -f 1,3 >group$i.size");}'
perl -e 'for($i=1;$i <=7;$i++){system("grep ^group$i groups.agp >group$i.agp");}'
perl -e 'for($i=1;$i <=7;$i++){system("python agp2assembly.py group$i.agp group$i.assembly");}'
sed -i 's/group//g' g*readnamesort.txt
sed -i 's/group//g' *.size
sed -i 's/group//g' g*.agp
perl -e 'for($i=1;$i <=7;$i++){system("java -jar juicer_tools.jar pre g$i-readnamesort.txt g$i-v1.hic group$i.size")}'
```

For the purposes of comparing against a known reference, generating a rough MUMmer plot of your assembly may be useful as well. Parameters shown below are to generate a quick and dirty plot, as the default will run for over a week on large legume genomes. 

Sample: 
```
nucmer -b 50 -l 500 -p IG72623-v1-vsLcb50l500 /isilon/groups/lentil/Lcu/Lcu.2RBY/pseudo/Lens_culinaris_2.0.fasta groups.asm.fasta
```

### 7) Iterate
 Create new pseudomolecules based on changes made in Juicebox, re-run ALLHiC build and step 6 as necessary until satisfied with the pseudomolecules.
 
 If contigs are broken during the Juicebox phase, the contig fasta file needs to be modified accordingly.
Sample:
```
grep fragment group*.review.assembly
cat fragments.txt |perl -plane '$_ =~ s/group.*assembly:>//;$_ =~ s/:::/\t/g;$_ =~ s/\s+/\t/g;$_ =~s/debris\t//;'|cut -f 1,2,4 >fragments-edit.txt 
cat fragments-edit.txt |perl fragmentbreaker.pl ../../hic/scaffolds-break/assembly.cleaned.fasta
```

### 8) Finalize Assembly
Plastid contamination will be present, at least at low levels, in raw sequences, and may be assembled and polished during the process. We often have chloroplast assemble as a single sequence, and mitochondria as 2-3 contigs. As a final clean up step, identify and remove these, as well as identify telomeric sequences and investigate their placement in the assembly. Create a list of contigs containing largely sequence to be removed.
Rename 'groups' to their corresponding chromosome in the groups.agp and groups.fasta file, then run the finalization script to rename assembly items and remove plastid-associated sequences from the final assembly.

Sample:
```
perl finalize-rename-assembly.pl Lnn.1TEST sample/allhic/hic-v2/groups.agp sample/allhic/hic-v2/assembly.cleaned.manualbreak1.fasta sample/allhic/hic-v2/groups.asm.fasta.rename IG_110813/plastidsearch/remove.list
```
(END)

