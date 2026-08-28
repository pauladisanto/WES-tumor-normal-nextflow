#!/usr/bin/env bash

set -euo pipefail

calls="$1"
annotation="$2"
output_tsv="$3"

if [[ "$annotation" == *.gz ]]; then
    gzip -cd -- "$annotation"
else
    cat -- "$annotation"
fi | awk -F '\t' 'BEGIN { OFS="\t" }
    $0 !~ /^#/ && $3 == "gene" {
        gene_id="."
        gene_name="."
        n=split($9, attributes, ";")
        for (i=1; i<=n; i++) {
            value=attributes[i]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if (value ~ /^gene_id[[:space:]]/) {
                sub(/^gene_id[[:space:]]+/, "", value)
                gsub(/^"|"$/, "", value)
                gene_id=value
            } else if (value ~ /^gene_name[[:space:]]/) {
                sub(/^gene_name[[:space:]]+/, "", value)
                gsub(/^"|"$/, "", value)
                gene_name=value
            }
        }
        print $1, $4-1, $5, gene_id, gene_name
    }' > genes.bed

{
    header=$(head -n 1 "$calls")
    printf '%s\tGENCODE_CHROM\tGENCODE_START\tGENCODE_END\tGENE_ID\tGENE_NAME\n' "$header"
    bedtools intersect \
        -a <(tail -n +2 "$calls") \
        -b genes.bed \
        -loj
} > "$output_tsv"
