process MUTECT2 {
    label 'gatk'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 4; memory '24 GB'; time '12h'; maxForks 1
    publishDir "${params.outdir}/mutect2/${pair_id}", mode: 'copy', pattern: '*.unfiltered.*'
    input:
    tuple val(pair_id), val(tumor_id), path(tumor_bam), path(tumor_bai), val(normal_id), path(normal_bam), path(normal_bai)
    tuple path(reference), path(fai), path(dict)
    tuple path(germline), path(germline_idx), path(pon), path(pon_idx)
    path targets
    output:
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.unfiltered.vcf.gz"), path("${tumor_id}_vs_${normal_id}.unfiltered.vcf.gz.tbi"), path("${tumor_id}_vs_${normal_id}.unfiltered.vcf.gz.stats"), emit: variants
    tuple val(pair_id), val(tumor_id), val(normal_id), path("${tumor_id}_vs_${normal_id}.f1r2.tar.gz"), emit: f1r2
    script:
    "wes_mutect2.sh ${tumor_id} ${normal_id} ${task.cpus} ${reference} ${tumor_bam} ${normal_bam} ${germline} ${pon} ${targets}"
}
