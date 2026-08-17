process VEP {
    label 'vep'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 4; memory '12 GB'; time '8h'
    publishDir "${params.outdir}/annotation/${pair_id}", mode: 'copy'
    input:
    tuple val(pair_id), val(tumor_id), val(normal_id), path(vcf), path(vcf_index)
    path vep_cache
    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.annotated.vcf.gz"), path("${tumor_id}_vs_${normal_id}.annotated.vcf.gz.tbi"), emit: annotated
    script:
    "wes_vep.sh ${tumor_id} ${normal_id} ${task.cpus} ${vcf} ${vep_cache}"
}
