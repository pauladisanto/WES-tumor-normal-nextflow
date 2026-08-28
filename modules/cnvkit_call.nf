process CNVKIT_CALL {
    label 'cnvkit'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 1; memory '4 GB'; time '2h'
    publishDir { "${params.outdir}/cnvkit/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(tumor_id), val(normal_id), path(segments)

    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}.cnv.call.cns"), emit: calls

    script:
    "wes_cnvkit_call.sh ${tumor_id} ${segments}"
}
