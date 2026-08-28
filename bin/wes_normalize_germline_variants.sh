#!/usr/bin/env bash

set -euo pipefail

sample="$1"
reference="$2"
input_vcf="$3"
output_vcf="${sample}.germline.normalized.vcf.gz"

# Left-align indels, check REF alleles, and split multiallelic records.
bcftools norm \
    --fasta-ref "$reference" \
    --multiallelics -any \
    --check-ref e \
    --output-type z \
    --output "$output_vcf" \
    "$input_vcf"

bcftools index --tbi "$output_vcf"
