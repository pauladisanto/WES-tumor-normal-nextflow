#!/usr/bin/env bash
set -euo pipefail
sample=$1; threads=$2; bam=$3; table=$4; reference=$5
gatk --java-options '-Xmx6g' ApplyBQSR -R "$reference" -I "$bam" --bqsr-recal-file "$table" \
  --create-output-bam-index false -O "${sample}.recal.bam"
samtools index -@ "$threads" "${sample}.recal.bam"
