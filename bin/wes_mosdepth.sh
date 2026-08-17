#!/usr/bin/env bash
set -euo pipefail
sample=$1; threads=$2; bam=$3; targets=$4
mosdepth --threads "$threads" --by "$targets" --no-per-base "$sample" "$bam"
