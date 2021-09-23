samtools faidx ../hic/racon-iter2i1.fasta
bamToBed -i merged.bam > alignment.bed
sort -k 4 alignment.bed > tmp && mv tmp alignment.bed

python SALSA-master/run_pipeline.py -a ../hic/racon-iter2i1.fasta -l racon-iter2i1.fasta.fai -b alignment.bed -e GATCGATC,GANTGATC,GANTANTC,GATCANTC -o scaffolds-break -m yes
