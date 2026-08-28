process GENOTYPE_GVCFS {
    label 'gatk'
    tag "${pair_id}: ${normal_id}"
    cpus 2; memory '12 GB'; time '12h'; maxForks 1
    publishDir { "${params.outdir}/germline/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(normal_id), path(gvcf), path(gvcf_index)
    tuple path(reference), path(fai), path(dict)
    path targets

    output:
    tuple val(pair_id), val(normal_id), path("${normal_id}.germline.raw.vcf.gz"), path("${normal_id}.germline.raw.vcf.gz.tbi"), emit: variants

    script:
    "wes_genotype_gvcfs.sh ${normal_id} ${reference} ${gvcf} ${targets}"
}
