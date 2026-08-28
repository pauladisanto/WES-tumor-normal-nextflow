#!/usr/bin/env bash

set -euo pipefail

input_cns="$1"
output_tsv="$2"

# Preserve every CNVkit column and append a readable state derived from the
# integer copy-number call. This is deliberately lightweight and transparent.
python3 - "$input_cns" "$output_tsv" <<'PY'
import csv
import sys

input_path, output_path = sys.argv[1:]

# CNVkit may place all genes from a large segment in one field. Python's CSV
# parser defaults to 128 KiB per field, which is too small for such segments.
csv.field_size_limit(sys.maxsize)

def state(value):
    if value in (None, "", "."):
        return "unknown"
    cn = int(round(float(value)))
    if cn == 0:
        return "homozygous_deletion"
    if cn == 1:
        return "loss"
    if cn == 2:
        return "neutral"
    if cn == 3:
        return "gain"
    return "amplification"

with open(input_path, newline="") as source, open(output_path, "w", newline="") as destination:
    reader = csv.DictReader(source, delimiter="\t")
    if not reader.fieldnames or "cn" not in reader.fieldnames:
        raise SystemExit("ERROR: CNVkit call file does not contain a 'cn' column")
    writer = csv.DictWriter(destination, fieldnames=[*reader.fieldnames, "state"], delimiter="\t")
    writer.writeheader()
    for row in reader:
        row["state"] = state(row.get("cn"))
        writer.writerow(row)
PY
