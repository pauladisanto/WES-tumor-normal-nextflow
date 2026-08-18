process LEARN_READ_ORIENTATION_MODEL {
    label 'gatk'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 1; memory '4 GB'; time '2h'
    publishDir { "${params.outdir}/mutect2/${pair_id}" }, mode: 'copy'
    input:
    tuple val(pair_id), val(tumor_id), val(normal_id), path(f1r2)
    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.orientation-priors.tar.gz"), emit: model
    script:
    "wes_learn_orientation.sh ${tumor_id} ${normal_id} ${f1r2}"
}
