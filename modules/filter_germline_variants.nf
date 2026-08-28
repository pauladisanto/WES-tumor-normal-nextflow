process FILTER_GERMLINE_VARIANTS {
    label 'gatk'
    tag "${pair_id}: ${normal_id}"
    cpus 2; memory '8 GB'; time '8h'
    publishDir { "${params.outdir}/germline/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(normal_id), path(vcf), path(vcf_index)
    tuple path(reference), path(fai), path(dict)

    output:
    tuple val(pair_id), val(normal_id), path("${normal_id}.germline.filtered.vcf.gz"), path("${normal_id}.germline.filtered.vcf.gz.tbi"), emit: filtered

    script:
    "wes_filter_germline_variants.sh ${normal_id} ${reference} ${vcf}"
}
