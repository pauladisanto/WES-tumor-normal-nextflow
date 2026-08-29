#!/usr/bin/env bash

set -euo pipefail

calls="$1"
annotation="$2"
output_tsv="$3"

tmpdir="$(mktemp -d)"
genes_bed="${tmpdir}/genes.bed"
compact_calls="${tmpdir}/altered_segments.bed"
compact_header="${tmpdir}/header.txt"

cleanup() {
    rm -f -- "$genes_bed" "$compact_calls" "$compact_header"
    rmdir -- "$tmpdir"
}
trap cleanup EXIT

# Extract one interval per GENCODE gene.
if [[ "$annotation" == *.gz ]]; then
    gzip -cd -- "$annotation"
else
    cat -- "$annotation"
fi |
awk -F '\t' '
BEGIN {
    OFS = "\t"
}
$0 !~ /^#/ && $3 == "gene" {
    gene_id = "."
    gene_name = "."

    number_attributes = split($9, attributes, ";")

    for (i = 1; i <= number_attributes; i++) {
        value = attributes[i]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)

        if (value ~ /^gene_id[[:space:]]/) {
            sub(/^gene_id[[:space:]]+/, "", value)
            gsub(/^"|"$/, "", value)
            gene_id = value
        } else if (value ~ /^gene_name[[:space:]]/) {
            sub(/^gene_name[[:space:]]+/, "", value)
            gsub(/^"|"$/, "", value)
            gene_name = value
        }
    }

    print $1, $4 - 1, $5, gene_id, gene_name
}
' > "$genes_bed"

# Remove CNVkit's very large gene column and retain only altered segments.
awk -F '\t' \
    -v header_file="$compact_header" '
BEGIN {
    OFS = "\t"
}
NR == 1 {
    gene_column = 0
    cn_column = 0

    for (i = 1; i <= NF; i++) {
        if ($i == "gene") {
            gene_column = i
        }
        if ($i == "cn") {
            cn_column = i
        }
    }

    if (gene_column == 0 || cn_column == 0) {
        print "ERROR: Expected gene and cn columns in CNVkit calls." > "/dev/stderr"
        exit 1
    }

    header = ""
    for (i = 1; i <= NF; i++) {
        if (i != gene_column) {
            header = header (header == "" ? "" : OFS) $i
        }
    }

    print header > header_file
    next
}
$cn_column != "." && $cn_column != 2 {
    row = ""

    for (i = 1; i <= NF; i++) {
        if (i != gene_column) {
            row = row (row == "" ? "" : OFS) $i
        }
    }

    print row
}
' "$calls" > "$compact_calls"

{
    printf '%s\tGENCODE_CHROM\tGENCODE_START\tGENCODE_END\tGENE_ID\tGENE_NAME\n' \
        "$(cat "$compact_header")"

    bedtools intersect \
        -a "$compact_calls" \
        -b "$genes_bed" \
        -loj
} > "$output_tsv"