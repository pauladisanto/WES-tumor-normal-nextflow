process VCF_TO_TSV {
    label 'bcftools'
    tag "${pair_id}: ${tumor_id}_vs_${normal_id}"
    cpus 1; memory '2 GB'; time '1h'
    publishDir "${params.outdir}/mutect2/${pair_id}", mode: 'copy'
    input:
    tuple val(pair_id), val(tumor_id), val(normal_id), path(vcf), path(vcf_index)
    output:
    path "${tumor_id}_vs_${normal_id}.final.tsv"
    script:
    "wes_vcf_to_tsv.sh ${vcf} ${tumor_id}_vs_${normal_id}.final.tsv"
}
