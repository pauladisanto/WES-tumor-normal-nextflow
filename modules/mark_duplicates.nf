process MARK_DUPLICATES {
    label 'alignment'
    tag "${pair_id}: ${sample_id}"
    cpus 4; memory '10 GB'; time '6h'; maxForks 2
    publishDir "${params.outdir}/markduplicates", mode: 'copy', pattern: '*.bam*'
    publishDir "${params.outdir}/markduplicates_metrics", mode: 'copy', pattern: '*.txt'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai)
    output:
    tuple val(pair_id), val(sample_id), val(role), path("${sample_id}.markdup.bam"), path("${sample_id}.markdup.bam.bai"), emit: bam
    tuple val(pair_id), val(sample_id), path("${sample_id}.markduplicates_metrics.txt"), emit: metrics
    script:
    "wes_mark_duplicates.sh ${sample_id} ${task.cpus} ${bam}"
}
