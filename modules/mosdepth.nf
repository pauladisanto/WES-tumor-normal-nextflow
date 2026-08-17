process MOSDEPTH {
    label 'alignment'
    tag "${pair_id}: ${sample_id}"
    cpus 2; memory '4 GB'; time '3h'
    publishDir "${params.outdir}/coverage", mode: 'copy'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(bam), path(bai)
    path targets
    output:
    tuple val(pair_id), val(sample_id), val(role), path("${sample_id}.mosdepth.summary.txt"), path("${sample_id}.mosdepth.global.dist.txt"), path("${sample_id}.regions.bed.gz"), path("${sample_id}.regions.bed.gz.csi"), emit: coverage
    script:
    "wes_mosdepth.sh ${sample_id} ${task.cpus} ${bam} ${targets}"
}
