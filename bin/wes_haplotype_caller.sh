#!/usr/bin/env bash
set -euo pipefail
sample=$1; threads=$2; bam=$3; reference=$4; targets=$5
gatk --java-options '-Xmx10g' HaplotypeCaller \
  -R "$reference" -I "$bam" -L "$targets" --native-pair-hmm-threads "$threads" \
  -ERC GVCF -O "${sample}.g.vcf.gz"
