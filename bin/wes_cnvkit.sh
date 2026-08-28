#!/usr/bin/env bash
set -euo pipefail
pair=$1; tumor=$2; tumor_bam=$3; normal_bam=$4; targets=$5; reference=$6

cnvkit.py batch "$tumor_bam" --normal "$normal_bam" --targets "$targets" \
  --fasta "$reference" --method hybrid --output-reference "${pair}.reference.cnn" \
  --output-dir . --diagram --scatter

# CNVkit derives its output prefix from the BAM sample name and may remove
# processing suffixes such as `.recal`. Use the biological tumor identifier,
# which matches the files produced by CNVkit for this workflow.
mv "${tumor}.cnr" "${tumor}.cnv.cnr"
mv "${tumor}.cns" "${tumor}.cnv.segments.cns"
