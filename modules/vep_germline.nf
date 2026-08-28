process VEP_GERMLINE {
    label 'vep'
    tag "${pair_id}: ${normal_id}"
    cpus 4; memory '12 GB'; time '8h'
    publishDir { "${params.outdir}/germline/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(normal_id), path(vcf), path(vcf_index)
    path vep_cache

    output:
    tuple val(pair_id), val(normal_id), path("${normal_id}.germline.annotated.vcf.gz"), path("${normal_id}.germline.annotated.vcf.gz.tbi"), emit: annotated

    script:
    "wes_vep_germline.sh ${normal_id} ${task.cpus} ${vcf} ${vep_cache}"
}
