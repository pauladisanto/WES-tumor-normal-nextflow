#!/usr/bin/env bash
set -euo pipefail
sample=$1; bam=$2; reference=$3; common_sites=$4; targets=$5
gatk --java-options '-Xmx4g' GetPileupSummaries \
  -R "$reference" -I "$bam" -V "$common_sites" -L "$targets" \
  -O "${sample}.pileups.table"
