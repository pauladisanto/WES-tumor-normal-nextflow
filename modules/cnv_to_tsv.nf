process CNV_TO_TSV {
    label 'cnvkit'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 1; memory '2 GB'; time '1h'
    publishDir { "${params.outdir}/cnvkit/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(tumor_id), val(normal_id), path(calls)

    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}.cnv.final.tsv"), emit: table

    script:
    "wes_cnv_to_tsv.sh ${calls} ${tumor_id}.cnv.final.tsv"
}
