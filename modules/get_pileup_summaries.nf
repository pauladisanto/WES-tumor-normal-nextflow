process GET_PILEUP_SUMMARIES {
    label 'gatk'
    tag "${pair_id}: ${sample_id}"
    cpus 1; memory '6 GB'; time '4h'
    publishDir "${params.outdir}/contamination/pileups", mode: 'copy'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai)
    tuple path(reference), path(fai), path(dict)
    tuple path(common_sites), path(common_sites_index)
    path targets
    output:
    tuple val(pair_id), val(sample_id), val(role), path("${sample_id}.pileups.table"), emit: pileups
    script:
    "wes_get_pileup_summaries.sh ${sample_id} ${bam} ${reference} ${common_sites} ${targets}"
}
