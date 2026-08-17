process BASE_RECALIBRATOR {
    label 'gatk'
    tag "${pair_id}: ${sample_id}"
    cpus 2; memory '8 GB'; time '6h'; maxForks 2
    publishDir "${params.outdir}/bqsr_tables", mode: 'copy', pattern: '*.recal.table'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai)
    tuple path(reference), path(fai), path(dict)
    tuple path(dbsnp), path(dbsnp_idx), path(indels), path(indels_idx), path(mills), path(mills_idx)
    output:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai), path("${sample_id}.recal.table"), emit: recalibration
    script:
    "wes_base_recalibrator.sh ${sample_id} ${bam} ${reference} ${dbsnp} ${indels} ${mills}"
}
