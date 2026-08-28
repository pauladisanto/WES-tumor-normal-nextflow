#!/usr/bin/env bash

set -euo pipefail

sample="$1"
reference="$2"
input_vcf="$3"
output_vcf="${sample}.germline.filtered.vcf.gz"

# SNP and indel annotations have different expected distributions, so GATK's
# generic small-callset hard filters are applied separately by variant type.
gatk --java-options '-Xmx6g' SelectVariants \
    -R "$reference" \
    -V "$input_vcf" \
    --select-type-to-include SNP \
    -O germline.snps.vcf.gz

gatk --java-options '-Xmx6g' VariantFiltration \
    -R "$reference" \
    -V germline.snps.vcf.gz \
    --filter-name SNP_QD2 \
    --filter-expression 'QD < 2.0' \
    --filter-name SNP_QUAL30 \
    --filter-expression 'QUAL < 30.0' \
    --filter-name SNP_FS60 \
    --filter-expression 'FS > 60.0' \
    --filter-name SNP_SOR3 \
    --filter-expression 'SOR > 3.0' \
    --filter-name SNP_MQ40 \
    --filter-expression 'MQ < 40.0' \
    --filter-name SNP_MQRankSum_low \
    --filter-expression 'MQRankSum < -12.5' \
    --filter-name SNP_ReadPosRankSum_low \
    --filter-expression 'ReadPosRankSum < -8.0' \
    -O germline.snps.filtered.vcf.gz

gatk --java-options '-Xmx6g' SelectVariants \
    -R "$reference" \
    -V "$input_vcf" \
    --select-type-to-include INDEL \
    --select-type-to-include MIXED \
    -O germline.indels.vcf.gz

gatk --java-options '-Xmx6g' VariantFiltration \
    -R "$reference" \
    -V germline.indels.vcf.gz \
    --filter-name INDEL_QD2 \
    --filter-expression 'QD < 2.0' \
    --filter-name INDEL_QUAL30 \
    --filter-expression 'QUAL < 30.0' \
    --filter-name INDEL_FS200 \
    --filter-expression 'FS > 200.0' \
    --filter-name INDEL_ReadPosRankSum_low \
    --filter-expression 'ReadPosRankSum < -20.0' \
    -O germline.indels.filtered.vcf.gz

gatk --java-options '-Xmx6g' MergeVcfs \
    -I germline.snps.filtered.vcf.gz \
    -I germline.indels.filtered.vcf.gz \
    -O "$output_vcf"

if [[ ! -f "${output_vcf}.tbi" ]]; then
    gatk IndexFeatureFile -I "$output_vcf"
fi
