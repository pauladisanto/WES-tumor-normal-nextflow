#!/usr/bin/env bash

# Arguments:
#   1: input VCF.GZ
#   2: output TSV

vcf=$1
output=$2

{
    printf 'CHROM\tPOS\tREF\tALT\tFILTER\tTLOD\tNLOD\tPOPAF'

    bcftools query -l "$vcf" |
    while read -r sample; do
        printf '\t%s_GT\t%s_DP\t%s_AD\t%s_AF' \
            "$sample" \
            "$sample" \
            "$sample" \
            "$sample"
    done

    printf '\n'

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT\t%FILTER\t%INFO/TLOD\t%INFO/NLOD\t%INFO/POPAF[\t%GT\t%DP\t%AD\t%AF]\n' \
        "$vcf"

} > "$output"