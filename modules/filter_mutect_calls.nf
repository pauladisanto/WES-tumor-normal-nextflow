process FILTER_MUTECT_CALLS {
    label 'gatk'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 2; memory '8 GB'; time '4h'
    publishDir { "${params.outdir}/mutect2/${pair_id}" }, mode: 'copy', pattern: '*.filtered.vcf.gz*'
    input:
    tuple val(pair_id), val(tumor_id), val(normal_id), path(vcf), path(vcf_index), path(stats), path(orientation_model), path(contamination), path(segments)
    tuple path(reference), path(fai), path(dict)
    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.filtered.vcf.gz"), path("${tumor_id}_vs_${normal_id}.filtered.vcf.gz.tbi"), emit: filtered
    script:
    "wes_filter_mutect_calls.sh ${tumor_id} ${normal_id} ${reference} ${vcf} ${stats} ${orientation_model} ${contamination} ${segments}"
}
