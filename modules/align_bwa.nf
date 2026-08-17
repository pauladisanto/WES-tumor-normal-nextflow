process ALIGN_BWA {
    label 'alignment'
    tag "${pair_id}: ${sample_id}"
    cpus 8; memory '10 GB'; time '8h'; maxForks 2
    publishDir "${params.outdir}/aligned", mode: 'copy', pattern: '*.bam*'
    input:
    tuple val(pair_id), val(sample_id), val(role), path(r1), path(r2)
    tuple path(reference), path(amb), path(ann), path(bwt), path(pac), path(sa)
    output:
    tuple val(pair_id), val(sample_id), val(role), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), emit: bam
    script:
    "wes_align_bwa.sh ${sample_id} ${task.cpus} ${reference} ${r1} ${r2}"
}
