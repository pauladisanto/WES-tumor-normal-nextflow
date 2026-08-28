process NORMALIZE_GERMLINE_VARIANTS {
    label 'bcftools'
    tag "${pair_id}: ${normal_id}"
    cpus 1; memory '4 GB'; time '4h'
    publishDir { "${params.outdir}/germline/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(normal_id), path(vcf), path(vcf_index)
    path reference

    output:
    tuple val(pair_id), val(normal_id), path("${normal_id}.germline.normalized.vcf.gz"), path("${normal_id}.germline.normalized.vcf.gz.tbi"), emit: normalized

    script:
    "wes_normalize_germline_variants.sh ${normal_id} ${reference} ${vcf}"
}
