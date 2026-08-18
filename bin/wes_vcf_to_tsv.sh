#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
    echo "Usage: wes_vcf_to_tsv.sh <annotated.vcf.gz> <output.tsv>" >&2
    exit 1
fi

input_vcf="$1"
output_tsv="$2"

if [[ ! -f "$input_vcf" ]]; then
    echo "ERROR: Input VCF does not exist: $input_vcf" >&2
    exit 1
fi

has_vep=false
if bcftools view -h "$input_vcf" | grep '^##INFO=<ID=CSQ,' > /dev/null; then
    has_vep=true
fi

mapfile -t samples < <(bcftools query -l "$input_vcf")

if [[ "${#samples[@]}" -eq 0 ]]; then
    echo "ERROR: No samples were found in the input VCF." >&2
    exit 1
fi

header=(
    "CHROM" "POS" "REF" "ALT" "FILTER"
    "TLOD" "NLOD" "POPAF"
    "GENE_SYMBOL" "GENE_ID" "TRANSCRIPT"
    "CONSEQUENCE" "IMPACT" "HGVSC" "HGVSP"
    "EXISTING_VARIATION" "CANONICAL" "SIFT" "POLYPHEN"
)

for sample in "${samples[@]}"; do
    header+=(
        "${sample}_GT"
        "${sample}_DP"
        "${sample}_AD"
        "${sample}_AF"
    )
done

(
    IFS=$'\t'
    echo "${header[*]}"
) > "$output_tsv"

base_format='%CHROM\t%POS\t%REF\t%ALT\t%FILTER'
base_format+='\t%INFO/TLOD\t%INFO/NLOD\t%INFO/POPAF'

sample_format='[\t%GT\t%DP\t%AD\t%AF]\n'

if [[ "$has_vep" == true ]]; then
    vep_format='\t%SYMBOL\t%Gene\t%Feature'
    vep_format+='\t%Consequence\t%IMPACT\t%HGVSc\t%HGVSp'
    vep_format+='\t%Existing_variation\t%CANONICAL\t%SIFT\t%PolyPhen'

    bcftools +split-vep "$input_vcf" \
        --select worst \
        --keep-sites \
        --allow-undef-tags \
        --format "${base_format}${vep_format}${sample_format}" \
        >> "$output_tsv"
else
    empty_vep_format='\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.'

    bcftools query \
        --allow-undef-tags \
        --format "${base_format}${empty_vep_format}${sample_format}" \
        "$input_vcf" \
        >> "$output_tsv"
fi
