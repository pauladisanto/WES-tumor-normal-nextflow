#!/usr/bin/env bash
set -euo pipefail
tumor=$1; normal=$2; reference=$3; vcf=$4; stats=$5; priors=$6; contamination=$7; segments=$8
prefix="${tumor}_vs_${normal}"
gatk --java-options '-Xmx6g' FilterMutectCalls \
  -R "$reference" -V "$vcf" --stats "$stats" \
  --ob-priors "$priors" --contamination-table "$contamination" \
  --tumor-segmentation "$segments" -O "${prefix}.filtered.vcf.gz"
