#!/usr/bin/env bash
sample=$1; threads=$2; bam=$3
mkdir -p tmp
picard -Xmx8g MarkDuplicates INPUT="$bam" OUTPUT="${sample}.markdup.bam" \
  METRICS_FILE="${sample}.markduplicates_metrics.txt" REMOVE_DUPLICATES=false \
  ASSUME_SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT TMP_DIR=tmp
samtools index -@ "$threads" "${sample}.markdup.bam"
