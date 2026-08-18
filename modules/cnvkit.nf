process CNVKIT {
    label 'cnvkit'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 4; memory '12 GB'; time '12h'; maxForks 1
    publishDir { "${params.outdir}/cnvkit/${pair_id}" }, mode: 'copy'
    input:
    tuple val(pair_id), val(tumor_id), path(tumor_bam), path(tumor_bai), val(normal_id), path(normal_bam), path(normal_bai)
    tuple path(reference), path(fai), path(dict)
    path targets
    output:
    path '*.cnr'
    path '*.cns'
    path '*.cnn'
    path '*.pdf'
    script:
    "wes_cnvkit.sh ${pair_id} ${tumor_bam} ${normal_bam} ${targets} ${reference}"
}
