process CALCULATE_CONTAMINATION {
    label 'gatk'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 1; memory '4 GB'; time '2h'
    publishDir "${params.outdir}/contamination/${pair_id}", mode: 'copy'
    input:
    tuple val(pair_id), val(tumor_id), path(tumor_pileups), val(normal_id), path(normal_pileups)
    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}.contamination.table"), path("${tumor_id}.segments.table"), emit: tables
    script:
    "wes_calculate_contamination.sh ${tumor_id} ${tumor_pileups} ${normal_pileups}"
}
