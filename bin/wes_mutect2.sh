#!/usr/bin/env bash

set -euo pipefail

# Positional arguments supplied by the Nextflow MUTECT2 module.
tumor="$1"       # Tumor sample identifier.
normal="$2"      # Matched-normal sample identifier.
threads="$3"     # Number of PairHMM threads assigned by Nextflow.
reference="$4"   # GRCh38 reference FASTA.
tumor_bam="$5"   # Recalibrated tumor BAM.
normal_bam="$6"  # Recalibrated matched-normal BAM.
germline="$7"    # Population allele frequencies: af-only-gnomAD.
pon="$8"         # Panel of Normals containing recurrent technical artifacts.
targets="$9"     # BED file containing the WES capture regions.

# Common prefix used for all tumor-normal output files.
prefix="${tumor}_vs_${normal}"

# Run Mutect2 in matched tumor-normal mode to identify candidate somatic
# SNVs and small indels within the WES target regions.
gatk --java-options '-Xms2g -Xmx18g' Mutect2 \
    -R "$reference" \
    -I "$tumor_bam" \
    -I "$normal_bam" \
    -normal "$normal" \
    --germline-resource "$germline" \
    --panel-of-normals "$pon" \
    --native-pair-hmm-threads "$threads" \
    -L "$targets" \
    --interval-padding 100 \
    --f1r2-tar-gz "${prefix}.f1r2.tar.gz" \
    -O "${prefix}.unfiltered.vcf.gz"

# Run GATK Mutect2 in matched tumor-normal mode to identify candidate somatic
# SNVs and small indels. Population allele frequencies from af-only gnomAD help
# distinguish somatic mutations from germline variants, while the Panel of
# Normals helps identify recurrent technical artifacts. Calling is restricted
# to the WES capture regions with 100-base interval padding. The script produces
# an unfiltered somatic VCF and F1R2 counts for orientation-bias modeling.