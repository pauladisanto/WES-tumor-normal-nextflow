process SAMTOOLS_QC_POSTDUP {
    label 'alignment'
    tag "${pair_id}: ${sample_id} (postdup)"
    cpus 4; memory '2 GB'; time '2h'
    publishDir "${params.outdir}/samtools_qc_postdup", mode: 'copy'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai)
    output:
    tuple val(pair_id), val(sample_id), path("${sample_id}.postdup.flagstat.txt"), path("${sample_id}.postdup.idxstats.txt"), path("${sample_id}.postdup.stats.txt"), emit: reports
    script:
    "wes_samtools_qc.sh ${sample_id} postdup ${task.cpus} ${bam}"
}
