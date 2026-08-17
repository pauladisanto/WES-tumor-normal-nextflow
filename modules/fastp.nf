process FASTP {
    label 'qc'
    tag "${pair_id}: ${sample_id}"
    cpus 4; memory '4 GB'; time '2h'
    publishDir "${params.outdir}/trimmed_reads", mode: 'copy', pattern: '*.fastq.gz'
    publishDir "${params.outdir}/fastp_reports", mode: 'copy', pattern: '*.fastp.html'
    publishDir "${params.outdir}/fastp_reports", mode: 'copy', pattern: '*.fastp.json'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(reads)
    output:
    tuple val(pair_id), val(sample_id), val(role), path("${sample_id}_1.trimmed.fastq.gz"), path("${sample_id}_2.trimmed.fastq.gz"), emit: reads
    tuple val(pair_id), val(sample_id), path("${sample_id}.fastp.html"), path("${sample_id}.fastp.json"), emit: reports
    script:
    "wes_fastp.sh ${sample_id} ${task.cpus} ${reads[0]} ${reads[1]}"
}
