#!/usr/bin/env bash
sample=$1; bam=$2; reference=$3; dbsnp=$4; indels=$5; mills=$6
gatk --java-options '-Xmx6g' BaseRecalibrator -R "$reference" -I "$bam" \
  --known-sites "$dbsnp" --known-sites "$indels" --known-sites "$mills" -O "${sample}.recal.table"
