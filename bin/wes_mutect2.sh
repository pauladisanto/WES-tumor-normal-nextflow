#!/usr/bin/env bash
tumor=$1; normal=$2; threads=$3; reference=$4; tumor_bam=$5; normal_bam=$6; germline=$7; pon=$8
prefix="${tumor}_vs_${normal}"
gatk --java-options '-Xms2g -Xmx18g' Mutect2 -R "$reference" -I "$tumor_bam" -I "$normal_bam" \
  -normal "$normal" --germline-resource "$germline" --panel-of-normals "$pon" \
  --native-pair-hmm-threads "$threads" --f1r2-tar-gz "${prefix}.f1r2.tar.gz" \
  -O "${prefix}.unfiltered.vcf.gz"
