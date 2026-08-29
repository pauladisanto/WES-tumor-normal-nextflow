#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
    echo "Usage: germline_vcf_to_tsv.sh <annotated.vcf.gz> <output.tsv>" >&2
    exit 1
fi

input_vcf="$1"
output_tsv="$2"

if [[ ! -f "$input_vcf" ]]; then
    echo "ERROR: Input VCF does not exist: $input_vcf" >&2
    exit 1
fi

mapfile -t samples < <(bcftools query -l "$input_vcf")
if [[ "${#samples[@]}" -ne 1 ]]; then
    echo "ERROR: Expected one sample in the germline VCF, found ${#samples[@]}." >&2
    exit 1
fi

has_vep=false
if bcftools view -h "$input_vcf" |
    grep '^##INFO=<ID=CSQ,' > /dev/null
then
    has_vep=true
fi

header=(
    CHROM POS ID REF ALT TYPE QUAL FILTER
    AC AN AF
    GENE_SYMBOL GENE_ID TRANSCRIPT MANE_SELECT CONSEQUENCE IMPACT
    HGVSC HGVSP EXISTING_VARIATION CLIN_SIG GNOMADE_AF GNOMADG_AF
    CANONICAL SIFT POLYPHEN
    GT FT GQ DP AD PL
)

(
    IFS=$'\t'
    echo "${header[*]}"
) > "$output_tsv"

base_format='%CHROM\t%POS\t%ID\t%REF\t%ALT\t%TYPE\t%QUAL\t%FILTER'
base_format+='\t%INFO/AC\t%INFO/AN\t%INFO/AF'

sample_format='[\t%GT\t%FT\t%GQ\t%DP\t%AD\t%PL]\n'

if [[ "$has_vep" == true ]]; then
    vep_format='\t%SYMBOL\t%Gene\t%Feature\t%MANE_SELECT'
    vep_format+='\t%Consequence\t%IMPACT\t%HGVSc\t%HGVSp'
    vep_format+='\t%Existing_variation\t%CLIN_SIG\t%gnomADe_AF\t%gnomADg_AF'
    vep_format+='\t%CANONICAL\t%SIFT\t%PolyPhen'

    bcftools +split-vep "$input_vcf" \
        --select worst \
        --keep-sites \
        --allow-undef-tags \
        --format "${base_format}${vep_format}${sample_format}" \
        >> "$output_tsv"
else
    empty_vep_format='\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.\t.'

    bcftools query \
        --allow-undef-tags \
        --format "${base_format}${empty_vep_format}${sample_format}" \
        "$input_vcf" \
        >> "$output_tsv"
fi