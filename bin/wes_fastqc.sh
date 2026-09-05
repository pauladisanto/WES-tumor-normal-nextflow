#!/usr/bin/env bash
set -euo pipefail

threads="$1"
stage="$2"
shift 2

renamed_reads=()

for read in "$@"; do
    filename="$(basename "$read")"

    if [[ "$filename" == *.fastq.gz ]]; then
        new_name="${filename%.fastq.gz}.${stage}.fastq.gz"
    elif [[ "$filename" == *.fq.gz ]]; then
        new_name="${filename%.fq.gz}.${stage}.fq.gz"
    else
        new_name="${filename}.${stage}"
    fi

    ln -s "$read" "$new_name"
    renamed_reads+=("$new_name")
done

fastqc \
    --threads "$threads" \
    "${renamed_reads[@]}"