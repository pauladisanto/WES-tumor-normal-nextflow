nextflow.enable.dsl = 2

params.input = "${projectDir}/samplesheet.csv"
params.outdir = "${projectDir}/results"
params.reference = "${projectDir}/reference/Homo_sapiens_assembly38.fasta"
params.reference_fai = "${projectDir}/reference/Homo_sapiens_assembly38.fasta.fai"
params.reference_dict = "${projectDir}/reference/Homo_sapiens_assembly38.dict"
params.dbsnp = "${projectDir}/reference/known_sites/Homo_sapiens_assembly38.dbsnp138.vcf"
params.dbsnp_index = "${params.dbsnp}.idx"
params.known_indels = "${projectDir}/reference/known_sites/Homo_sapiens_assembly38.known_indels.vcf.gz"
params.known_indels_index = "${params.known_indels}.tbi"
params.mills_indels = "${projectDir}/reference/known_sites/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
params.mills_indels_index = "${params.mills_indels}.tbi"
params.germline_resource = "${projectDir}/reference/somatic/af-only-gnomad.hg38.vcf.gz"
params.germline_resource_index = "${params.germline_resource}.tbi"
params.panel_of_normals = "${projectDir}/reference/somatic/1000g_pon.hg38.vcf.gz"
params.panel_of_normals_index = "${params.panel_of_normals}.tbi"

process FASTQC_RAW {
  tag "${sample_id} (raw)"; cpus 2; memory '2 GB'; time '2h'
  publishDir "${params.outdir}/fastqc_raw", mode: 'copy'
  input: tuple val(sample_id), val(role), path(reads)
  output: path '*_fastqc.html'; path '*_fastqc.zip'
  script: "wes_fastqc.sh ${task.cpus} ${reads}"
}

process FASTP {
    tag "${sample_id}"

    cpus 4
    memory '4 GB'
    time '2h'

    publishDir "${params.outdir}/trimmed_reads",
        mode: 'copy',
        pattern: '*.fastq.gz'

    publishDir "${params.outdir}/fastp_reports",
        mode: 'copy',
        pattern: '*.fastp.{html,json}'

    input:
    tuple val(sample_id), val(role), path(reads)

    output:
    tuple val(sample_id),
          val(role),
          path("${sample_id}_1.trimmed.fastq.gz"),
          path("${sample_id}_2.trimmed.fastq.gz"),
          emit: reads

    path "${sample_id}.fastp.html",
        emit: html

    path "${sample_id}.fastp.json",
        emit: json

    script:
    """
    wes_fastp.sh \
        ${sample_id} \
        ${task.cpus} \
        ${reads[0]} \
        ${reads[1]}
    """
}

process FASTQC_TRIMMED {
  tag "${sample_id} (trimmed)"; cpus 2; memory '2 GB'; time '2h'
  publishDir "${params.outdir}/fastqc_trimmed", mode: 'copy'
  input: tuple val(sample_id), val(role), path(reads)
  output: path '*_fastqc.html'; path '*_fastqc.zip'
  script: "wes_fastqc.sh ${task.cpus} ${reads}"
}

process BWA_INDEX {
    tag "${reference.simpleName}"

    cpus 1
    memory '10 GB'
    time '12h'
    maxForks 1

    publishDir "${projectDir}/reference",
        mode: 'copy',
        overwrite: false,
        pattern: '*.amb'

    publishDir "${projectDir}/reference",
        mode: 'copy',
        overwrite: false,
        pattern: '*.ann'

    publishDir "${projectDir}/reference",
        mode: 'copy',
        overwrite: false,
        pattern: '*.bwt'

    publishDir "${projectDir}/reference",
        mode: 'copy',
        overwrite: false,
        pattern: '*.pac'

    publishDir "${projectDir}/reference",
        mode: 'copy',
        overwrite: false,
        pattern: '*.sa'

    input:
    path reference

    output:
    tuple path(reference),
          path("${reference}.amb"),
          path("${reference}.ann"),
          path("${reference}.bwt"),
          path("${reference}.pac"),
          path("${reference}.sa"),
          emit: index

    script:
    """
    wes_bwa_index.sh ${reference}
    """
}

process ALIGN_BWA {
  tag "$sample_id"; cpus 8; memory '10 GB'; time '8h'; maxForks 2
  publishDir "${params.outdir}/aligned", mode: 'copy', pattern: '*.bam*'
  input:
  tuple val(sample_id), val(role), path(r1), path(r2)
  tuple path(reference), path(amb), path(ann), path(bwt), path(pac), path(sa)
  output: tuple val(sample_id), val(role), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), emit: bam
  script: "wes_align_bwa.sh ${sample_id} ${task.cpus} ${reference} ${r1} ${r2}"
}

process SAMTOOLS_QC_PREDUP {
  tag "${sample_id} (predup)"; cpus 4; memory '2 GB'; time '2h'
  publishDir "${params.outdir}/samtools_qc_predup", mode: 'copy'
  input: tuple val(sample_id), val(role), path(bam), path(bai)
  output: path "${sample_id}.predup.flagstat.txt"; path "${sample_id}.predup.idxstats.txt"; path "${sample_id}.predup.stats.txt"
  script: "wes_samtools_qc.sh ${sample_id} predup ${task.cpus} ${bam}"
}

process MARK_DUPLICATES {
  tag "$sample_id"; cpus 4; memory '10 GB'; time '6h'; maxForks 2
  publishDir "${params.outdir}/markduplicates", mode: 'copy', pattern: '*.bam*'
  publishDir "${params.outdir}/markduplicates_metrics", mode: 'copy', pattern: '*.txt'
  input: tuple val(sample_id), val(role), path(bam), path(bai)
  output:
  tuple val(sample_id), val(role), path("${sample_id}.markdup.bam"), path("${sample_id}.markdup.bam.bai"), emit: bam
  path "${sample_id}.markduplicates_metrics.txt", emit: metrics
  script: "wes_mark_duplicates.sh ${sample_id} ${task.cpus} ${bam}"
}

process SAMTOOLS_QC_POSTDUP {
  tag "${sample_id} (postdup)"; cpus 4; memory '2 GB'; time '2h'
  publishDir "${params.outdir}/samtools_qc_postdup", mode: 'copy'
  input: tuple val(sample_id), val(role), path(bam), path(bai)
  output: path "${sample_id}.postdup.flagstat.txt"; path "${sample_id}.postdup.idxstats.txt"; path "${sample_id}.postdup.stats.txt"
  script: "wes_samtools_qc.sh ${sample_id} postdup ${task.cpus} ${bam}"
}

process BASE_RECALIBRATOR {
  tag "$sample_id"; cpus 2; memory '8 GB'; time '6h'; maxForks 2
  publishDir "${params.outdir}/bqsr_tables", mode: 'copy', pattern: '*.recal.table'
  input:
  tuple val(sample_id), val(role), path(bam), path(bai)
  tuple path(reference), path(fai), path(dict)
  tuple path(dbsnp), path(dbsnp_idx), path(indels), path(indels_idx), path(mills), path(mills_idx)
  output: tuple val(sample_id), val(role), path(bam), path(bai), path("${sample_id}.recal.table"), emit: recalibration
  script: "wes_base_recalibrator.sh ${sample_id} ${bam} ${reference} ${dbsnp} ${indels} ${mills}"
}

process APPLY_BQSR {
  tag "$sample_id"; cpus 2; memory '8 GB'; time '6h'; maxForks 2
  publishDir "${params.outdir}/bqsr_bam", mode: 'copy', pattern: '*.bam*'
  input:
  tuple val(sample_id), val(role), path(bam), path(bai), path(recal_table)
  tuple path(reference), path(fai), path(dict)
  output: tuple val(sample_id), val(role), path("${sample_id}.recal.bam"), path("${sample_id}.recal.bam.bai"), emit: bam
  script: "wes_apply_bqsr.sh ${sample_id} ${task.cpus} ${bam} ${recal_table} ${reference}"
}

process MUTECT2 {
  tag "${tumor_id}_vs_${normal_id}"; cpus 4; memory '24 GB'; time '12h'; maxForks 1
  publishDir "${params.outdir}/mutect2", mode: 'copy'
  input:
  tuple val(tumor_id), path(tumor_bam), path(tumor_bai), val(normal_id), path(normal_bam), path(normal_bai)
  tuple path(reference), path(fai), path(dict)
  tuple path(germline), path(germline_idx), path(pon), path(pon_idx)
  output:
  tuple val(tumor_id),
        val(normal_id),
        path("${tumor_id}_vs_${normal_id}.unfiltered.vcf.gz"),
        path("${tumor_id}_vs_${normal_id}.unfiltered.vcf.gz.tbi"),
        emit: variants

  path "${tumor_id}_vs_${normal_id}.unfiltered.vcf.gz.stats",
      emit: stats

  path "${tumor_id}_vs_${normal_id}.f1r2.tar.gz",
      emit: f1r2 

  script: "wes_mutect2.sh ${tumor_id} ${normal_id} ${task.cpus} ${reference} ${tumor_bam} ${normal_bam} ${germline} ${pon}"
}

process VCF_TO_TSV {
    tag "${tumor_id}_vs_${normal_id}"

    cpus 1
    memory '2 GB'
    time '1h'

    publishDir "${params.outdir}/mutect2",
        mode: 'copy',
        pattern: '*.unfiltered.tsv'

    input:
    tuple val(tumor_id),
          val(normal_id),
          path(vcf),
          path(vcf_index)

    output:
    path "${tumor_id}_vs_${normal_id}.unfiltered.tsv",
        emit: tsv

    script:
    """
    wes_vcf_to_tsv.sh \
        ${vcf} \
        ${tumor_id}_vs_${normal_id}.unfiltered.tsv
    """
}

workflow {
  samples_ch = Channel.fromPath(params.input, checkIfExists: true).splitCsv(header: true).map { row ->
    assert row.sample && row.role && row.fastq_1 && row.fastq_2 : 'Required columns: sample,role,fastq_1,fastq_2'
    def role = row.role.trim().toLowerCase()
    assert role in ['tumor','normal'] : "Invalid role for ${row.sample}"
    tuple(row.sample.trim(), role, file(row.fastq_1.trim(), checkIfExists: true), file(row.fastq_2.trim(), checkIfExists: true))
  }
  raw_reads_ch = samples_ch.map { id, role, r1, r2 -> tuple(id, role, [r1,r2]) }
  FASTQC_RAW(raw_reads_ch)
  FASTP(raw_reads_ch)
  trimmed_qc_ch = FASTP.out.reads.map { id, role, r1, r2 -> tuple(id, role, [r1,r2]) }
  FASTQC_TRIMMED(trimmed_qc_ch)

  gatk_ref_ch = Channel.value(tuple(file(params.reference, checkIfExists: true), file(params.reference_fai, checkIfExists: true), file(params.reference_dict, checkIfExists: true)))
  bqsr_ch = Channel.value(tuple(file(params.dbsnp, checkIfExists: true), file(params.dbsnp_index, checkIfExists: true), file(params.known_indels, checkIfExists: true), file(params.known_indels_index, checkIfExists: true), file(params.mills_indels, checkIfExists: true), file(params.mills_indels_index, checkIfExists: true)))
  somatic_ch = Channel.value(tuple(file(params.germline_resource, checkIfExists: true), file(params.germline_resource_index, checkIfExists: true), file(params.panel_of_normals, checkIfExists: true), file(params.panel_of_normals_index, checkIfExists: true)))

  reference_file = file(params.reference, checkIfExists: true)

  bwa_index_paths = [
    "${params.reference}.amb",
    "${params.reference}.ann",
    "${params.reference}.bwt",
    "${params.reference}.pac",
    "${params.reference}.sa"
  ]

  bwa_index_exists = bwa_index_paths.every { index_path ->
    file(index_path).exists()
  }

  if (bwa_index_exists) {
    log.info "Existing BWA index found. Skipping BWA_INDEX."

    bwa_index_ch = Channel.value(
      tuple(
        reference_file,
        file("${params.reference}.amb", checkIfExists: true),
        file("${params.reference}.ann", checkIfExists: true),
        file("${params.reference}.bwt", checkIfExists: true),
        file("${params.reference}.pac", checkIfExists: true),
        file("${params.reference}.sa", checkIfExists: true)
      )
    )
  }
  else {
    log.info "Complete BWA index not found. Running BWA_INDEX."

    reference_ch = Channel.value(reference_file)
    BWA_INDEX(reference_ch)
    bwa_index_ch = BWA_INDEX.out.index
  }

  ALIGN_BWA(FASTP.out.reads, bwa_index_ch)
  SAMTOOLS_QC_PREDUP(ALIGN_BWA.out.bam)
  MARK_DUPLICATES(ALIGN_BWA.out.bam)
  SAMTOOLS_QC_POSTDUP(MARK_DUPLICATES.out.bam)
  BASE_RECALIBRATOR(MARK_DUPLICATES.out.bam, gatk_ref_ch, bqsr_ch)
  APPLY_BQSR(BASE_RECALIBRATOR.out.recalibration, gatk_ref_ch)

  tumor_ch = APPLY_BQSR.out.bam.filter { id, role, bam, bai -> role == 'tumor' }.map { id, role, bam, bai -> tuple(id,bam,bai) }
  normal_ch = APPLY_BQSR.out.bam.filter { id, role, bam, bai -> role == 'normal' }.map { id, role, bam, bai -> tuple(id,bam,bai) }
  MUTECT2(tumor_ch.combine(normal_ch), gatk_ref_ch, somatic_ch)
  VCF_TO_TSV(MUTECT2.out.variants)
}
