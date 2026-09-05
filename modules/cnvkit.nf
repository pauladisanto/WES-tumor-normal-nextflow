process CNVKIT {
    label 'cnvkit'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 4; memory '6 GB'; time '4h'; maxForks 1
    publishDir { "${params.outdir}/cnvkit/${pair_id}" }, mode: 'copy'
    input:
    tuple val(pair_id), val(tumor_id), path(tumor_bam), path(tumor_bai), val(normal_id), path(normal_bam), path(normal_bai)
    tuple path(reference), path(fai), path(dict)
    path targets
    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}.cnv.cnr"), emit: ratios
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}.cnv.segments.cns"), emit: segments
    path '*.cnn', emit: references
    path '*.pdf', emit: plots
    path '*.png', emit: scatter
    script:
    "wes_cnvkit.sh ${pair_id} ${tumor_id} ${tumor_bam} ${normal_bam} ${targets} ${reference}"
}
