process HAPLOTYPE_CALLER {
    label 'gatk'
    tag "${pair_id}: ${normal_id}"
    cpus 4; memory '12 GB'; time '12h'; maxForks 1
    publishDir "${params.outdir}/germline/${pair_id}", mode: 'copy'
    input:
    tuple val(pair_id), val(normal_id), path(normal_bam), path(normal_bai)
    tuple path(reference), path(fai), path(dict)
    path targets
    output:
    tuple val(pair_id), val(normal_id), path("${normal_id}.g.vcf.gz"), path("${normal_id}.g.vcf.gz.tbi"), emit: gvcf
    script:
    "wes_haplotype_caller.sh ${normal_id} ${task.cpus} ${normal_bam} ${reference} ${targets}"
}
