#!/usr/bin/env bash
set -euo pipefail
pair=$1; tumor_bam=$2; normal_bam=$3; targets=$4; reference=$5
cnvkit.py batch "$tumor_bam" --normal "$normal_bam" --targets "$targets" \
  --fasta "$reference" --method hybrid --output-reference "${pair}.reference.cnn" \
  --output-dir . --diagram --scatter
