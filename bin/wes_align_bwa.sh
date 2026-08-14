#!/usr/bin/env bash
sample=$1; threads=$2; reference=$3; r1=$4; r2=$5
sort_threads=2
bwa_threads=$((threads-sort_threads))
bwa mem -M -t "$bwa_threads" -R "@RG\tID:${sample}\tSM:${sample}\tLB:${sample}\tPL:ILLUMINA" "$reference" "$r1" "$r2" \
  | samtools sort --threads "$sort_threads" -m 2G --output-fmt BAM -o "${sample}.sorted.bam"
samtools index -@ "$threads" "${sample}.sorted.bam"
