process ANNOTATE_CNV_GENES {
    label 'cnv_annotation'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 1; memory '2 GB'; time '1h'
    publishDir { "${params.outdir}/cnvkit/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(tumor_id), val(normal_id), path(calls)
    path gene_annotation

    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}.cnv.genes.tsv"), emit: annotated

    script:
    "wes_annotate_cnv_genes.sh ${calls} ${gene_annotation} ${tumor_id}.cnv.genes.tsv"
}
