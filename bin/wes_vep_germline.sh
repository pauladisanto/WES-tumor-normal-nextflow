#!/usr/bin/env bash

set -euo pipefail

sample="$1"
threads="$2"
input_vcf="$3"
vep_cache="$4"
output_vcf="${sample}.germline.annotated.vcf.gz"

# Add functional consequences and population/clinical annotations available
# in the installed offline VEP cache.
vep \
    --input_file "$input_vcf" \
    --output_file "$output_vcf" \
    --format vcf \
    --vcf \
    --compress_output bgzip \
    --cache \
    --offline \
    --dir_cache "$vep_cache" \
    --species homo_sapiens \
    --assembly GRCh38 \
    --everything \
    --fork "$threads" \
    --force_overwrite \
    --no_stats

tabix -f -p vcf "$output_vcf"
