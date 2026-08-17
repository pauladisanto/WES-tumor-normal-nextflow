process SAMTOOLS_QC_PREDUP {
    label 'alignment'
    tag "${pair_id}: ${sample_id} (predup)"
    cpus 4; memory '2 GB'; time '2h'
    publishDir "${params.outdir}/samtools_qc_predup", mode: 'copy'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai)
    output:
    tuple val(pair_id), val(sample_id), path("${sample_id}.predup.flagstat.txt"), path("${sample_id}.predup.idxstats.txt"), path("${sample_id}.predup.stats.txt"), emit: reports
    script:
    "wes_samtools_qc.sh ${sample_id} predup ${task.cpus} ${bam}"
}
