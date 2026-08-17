#!/usr/bin/env bash
set -euo pipefail
tumor=$1; normal=$2; threads=$3; vcf=$4; cache=$5
output="${tumor}_vs_${normal}.annotated.vcf.gz"
vep --input_file "$vcf" --output_file "$output" --format vcf --vcf \
  --compress_output bgzip --cache --offline --dir_cache "$cache" \
  --species homo_sapiens --assembly GRCh38 --everything --fork "$threads" --force_overwrite
tabix -f -p vcf "$output"
