#!/usr/bin/env bash
sample=$1; threads=$2; r1=$3; r2=$4
fastp --in1 "$r1" --in2 "$r2" --out1 "${sample}_1.trimmed.fastq.gz" --out2 "${sample}_2.trimmed.fastq.gz" \
  --detect_adapter_for_pe --qualified_quality_phred 20 --unqualified_percent_limit 40 \
  --n_base_limit 5 --length_required 30 --thread "$threads" \
  --html "${sample}.fastp.html" --json "${sample}.fastp.json"
