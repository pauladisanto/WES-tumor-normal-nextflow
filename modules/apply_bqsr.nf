process APPLY_BQSR {
    label 'gatk'
    tag "${pair_id}: ${sample_id}"
    cpus 2; memory '8 GB'; time '6h'; maxForks 2
    publishDir "${params.outdir}/bqsr_bam", mode: 'copy', pattern: '*.bam*'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai), path(recal_table)
    tuple path(reference), path(fai), path(dict)
    output:
    tuple val(pair_id), val(sample_id), val(role), path("${sample_id}.recal.bam"), path("${sample_id}.recal.bam.bai"), emit: bam
    script:
    "wes_apply_bqsr.sh ${sample_id} ${task.cpus} ${bam} ${recal_table} ${reference}"
}
