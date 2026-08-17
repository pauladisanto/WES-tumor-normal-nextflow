#!/usr/bin/env bash
set -euo pipefail
tumor=$1; tumor_pileups=$2; normal_pileups=$3
gatk --java-options '-Xmx3g' CalculateContamination \
  -I "$tumor_pileups" -matched "$normal_pileups" \
  -O "${tumor}.contamination.table" --tumor-segmentation "${tumor}.segments.table"
