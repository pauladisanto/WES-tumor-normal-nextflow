#!/usr/bin/env bash
set -euo pipefail
sample=$1; stage=$2; threads=$3; bam=$4
samtools quickcheck -v "$bam"
samtools flagstat -@ "$threads" "$bam" > "${sample}.${stage}.flagstat.txt"
samtools idxstats "$bam" > "${sample}.${stage}.idxstats.txt"
samtools stats -@ "$threads" "$bam" > "${sample}.${stage}.stats.txt"
