#!/usr/bin/env bash
set -euo pipefail

pair=$1
tumor=$2
tumor_bam=$3
normal_bam=$4
targets=$5
reference=$6

cnvkit.py batch "$tumor_bam" \
  --normal "$normal_bam" \
  --targets "$targets" \
  --fasta "$reference" \
  --method hybrid \
  --output-reference "${pair}.reference.cnn" \
  --output-dir . \
  --scatter

# Create a clean chromosome-level CNV diagram without gene labels
cnvkit.py diagram "${tumor}.cnr" \
  --segment "${tumor}.cns" \
  --no-gene-labels \
  --title "Sample ${tumor}" \
  --output "${tumor}.cnv.diagram.pdf"

# Standardise filenames for downstream workflow steps
mv "${tumor}.cnr" "${tumor}.cnv.cnr"
mv "${tumor}.cns" "${tumor}.cnv.segments.cns"