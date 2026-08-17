process MULTIQC {
    label 'qc'
    tag 'cohort QC'
    cpus 2
    memory '4 GB'
    time '2h'
    publishDir "${params.outdir}/multiqc", mode: 'copy'
    input:
    path qc_files
    output:
    path 'multiqc_report.html'
    path 'multiqc_report_data'
    script:
    "wes_multiqc.sh ${task.cpus}"
}
