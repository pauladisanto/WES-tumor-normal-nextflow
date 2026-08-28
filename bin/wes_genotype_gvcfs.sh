#!/usr/bin/env bash

set -euo pipefail

sample="$1"
reference="$2"
gvcf="$3"
targets="$4"

# Convert the single-sample gVCF into a regular, genotyped germline VCF.
gatk --java-options '-Xmx10g' GenotypeGVCFs \
    -R "$reference" \
    -V "$gvcf" \
    -L "$targets" \
    -O "${sample}.germline.raw.vcf.gz" \
    --create-output-variant-index true
