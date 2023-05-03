#!/bin/bash

# If running for the first time, first grant permission to run the script by running:
# chmod 755 run.sh
# first gunzip all files using the command: find (PATH_OF_THE_FOLDER) -name \*.gz -exec gunzip {} \; 

# for customised python script, add "#!/usr/bin/env python" on the first line, remove .py filename 
# and activate using chmod 755

# $1 = 1st paired-end fastq
# $2 = 2nd paired-end fastq 
# $3 = ref_seq in fasta

# Declare inputs
cp $1 $2 $3

# Build index files for Bowtie2 alignment
Desktop/iSeq-master/bowtie2-2.3.2-legacy/bowtie2-build -f $3 $3

# Alignment   
# --minis set min distance between paired end, default is 0; --maxins set the maximun default is 500 (total length inc read)
# -x = ref fasta; -1 = paired-end read 1; -2 = paired-end read 2; --al-conc = output only concordantly aligned reads
# 2>$3 output the stat of the read
(Desktop/iSeq-master/bowtie2-2.3.2-legacy/bowtie2 --local --minins 0 --maxins 2000 -x $3 -1 $1 -2 $2 -S $3.sam --al-conc $3.con.sam) 2>$3.stat.txt 






# Convert sam to bam file
Desktop/iSeq-master/samtools-1.3.1/samtools view -bS $3.sam > $3.bam

# Sorted bam file
Desktop/iSeq-master/samtools-1.3.1/samtools sort $3.bam -o $3_sorted.bam

# Index _sorted.bam file
Desktop/iSeq-master/samtools-1.3.1/samtools index $3_sorted.bam

# Call variant
# samtools mpileup -ugf $3 $3_sorted.bam |bcftools call -vmO v -o $3_call.vcf

# Export pileup as wig using igvtools
Desktop/iSeq-master/IGVTools/igvtools count -z 1 -w 1 --bases $3_sorted.bam $3_sorted.wig $3

# Convert wig to csv
mv $3_sorted.wig $3_sorted.wig.csv

# Customised python script to call variant (deletion included) based on the most read base
# First argue = csv file from igvtools; second argue = ref fast
Desktop/iSeq-master/call.py $3_sorted.wig.csv $3 

# Generate consensus txt file
Desktop/iSeq-master/consensus.py $3_sorted.wig.csv
