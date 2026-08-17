process FASTQC_TRIMMED {
    label 'qc'
    tag "${pair_id}: ${sample_id} (trimmed)"
    cpus 2; memory '2 GB'; time '2h'
    publishDir "${params.outdir}/fastqc_trimmed", mode: 'copy'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(reads)
    output:
    tuple val(pair_id), val(sample_id), path('*_fastqc.html'), path('*_fastqc.zip'), emit: reports
    script:
    "wes_fastqc.sh ${task.cpus} ${reads}"
}
