process GERMLINE_VCF_TO_TSV {
    label 'bcftools'
    tag "${pair_id}: ${normal_id}"
    cpus 1; memory '2 GB'; time '1h'
    publishDir { "${params.outdir}/germline/${pair_id}" }, mode: 'copy'

    input:
    tuple val(pair_id), val(normal_id), path(vcf), path(vcf_index)

    output:
    tuple val(pair_id), val(normal_id), path("${normal_id}.germline.final.tsv"), emit: table

    script:
    "wes_germline_vcf_to_tsv.sh ${vcf} ${normal_id}.germline.final.tsv"
}
