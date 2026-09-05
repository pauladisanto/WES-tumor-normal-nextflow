nextflow.enable.dsl = 2

include { FASTQC_RAW } from './modules/fastqc_raw'
include { FASTP } from './modules/fastp'
include { FASTQC_TRIMMED } from './modules/fastqc_trimmed'
include { BWA_INDEX } from './modules/bwa_index'
include { ALIGN_BWA } from './modules/align_bwa'
include { SAMTOOLS_QC_PREDUP } from './modules/samtools_qc_predup'
include { MARK_DUPLICATES } from './modules/mark_duplicates'
include { SAMTOOLS_QC_POSTDUP } from './modules/samtools_qc_postdup'
include { BASE_RECALIBRATOR } from './modules/base_recalibrator'
include { APPLY_BQSR } from './modules/apply_bqsr'
include { MOSDEPTH } from './modules/mosdepth'
include { GET_PILEUP_SUMMARIES } from './modules/get_pileup_summaries'
include { MUTECT2 } from './modules/mutect2'
include { LEARN_READ_ORIENTATION_MODEL } from './modules/learn_read_orientation_model'
include { CALCULATE_CONTAMINATION } from './modules/calculate_contamination'
include { FILTER_MUTECT_CALLS } from './modules/filter_mutect_calls'
include { VEP } from './modules/vep'
include { VCF_TO_TSV } from './modules/vcf_to_tsv'
include { CNVKIT } from './modules/cnvkit'
include { CNVKIT_CALL } from './modules/cnvkit_call'
include { CNV_TO_TSV } from './modules/cnv_to_tsv'
include { ANNOTATE_CNV_GENES } from './modules/annotate_cnv_genes'
include { HAPLOTYPE_CALLER } from './modules/haplotype_caller'
include { GENOTYPE_GVCFS } from './modules/genotype_gvcfs'
include { NORMALIZE_GERMLINE_VARIANTS } from './modules/normalize_germline_variants'
include { FILTER_GERMLINE_VARIANTS } from './modules/filter_germline_variants'
include { VEP_GERMLINE } from './modules/vep_germline'
include { GERMLINE_VCF_TO_TSV } from './modules/germline_vcf_to_tsv' 
include { MULTIQC } from './modules/multiqc'


workflow {
    samples_ch = Channel.fromPath(params.input, checkIfExists: true).splitCsv(header: true).map { row ->
        assert row.pair_id && row.sample && row.role && row.fastq_1 && row.fastq_2 : 'Required columns: pair_id,sample,role,fastq_1,fastq_2'
        def pair_id = row.pair_id.trim()
        def sample_id = row.sample.trim()
        def role = row.role.trim().toLowerCase()
        assert pair_id ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/ : "Unsafe pair_id: ${pair_id}"
        assert sample_id ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/ : "Unsafe sample identifier: ${sample_id}"
        assert role in ['tumor', 'normal'] : "Invalid role for ${sample_id}: ${row.role}"
        tuple(pair_id, sample_id, role, file(row.fastq_1.trim(), checkIfExists: true), file(row.fastq_2.trim(), checkIfExists: true))
    }

    pair_validation_ch = samples_ch
        .map { pair_id, sample_id, role, r1, r2 -> tuple(pair_id, role) }
        .groupTuple()
        .map { pair_id, roles ->
            assert roles.count { it == 'tumor' } == 1 : "${pair_id} must contain exactly one tumor sample"
            assert roles.count { it == 'normal' } == 1 : "${pair_id} must contain exactly one normal sample"
            tuple(pair_id, true)
        }

    sample_validation_ch = samples_ch
        .map { pair_id, sample_id, role, r1, r2 -> tuple(sample_id, pair_id) }
        .groupTuple()
        .map { sample_id, pair_ids ->
            assert pair_ids.size() == 1 : "Sample identifier ${sample_id} is repeated; sample identifiers must be globally unique"
            tuple(pair_ids[0], sample_id, true)
        }

    pair_validated_samples_ch = samples_ch
        .combine(pair_validation_ch, by: 0)
        .map { pair_id, sample_id, role, r1, r2, valid ->
            tuple(pair_id, sample_id, role, r1, r2)
        }

    validated_samples_ch = pair_validated_samples_ch
        .join(sample_validation_ch, by: [0, 1])
        .map { pair_id, sample_id, role, r1, r2, valid -> tuple(pair_id, sample_id, role, r1, r2) }

    raw_reads_ch = validated_samples_ch.map { pair_id, sample_id, role, r1, r2 -> tuple(pair_id, sample_id, role, [r1, r2]) }
    FASTQC_RAW(raw_reads_ch)
    FASTP(raw_reads_ch)
    trimmed_qc_ch = FASTP.out.reads.map { pair_id, sample_id, role, r1, r2 -> tuple(pair_id, sample_id, role, [r1, r2]) }
    FASTQC_TRIMMED(trimmed_qc_ch)

    gatk_ref_ch = Channel.value(tuple(file(params.reference, checkIfExists: true), file(params.reference_fai, checkIfExists: true), file(params.reference_dict, checkIfExists: true)))
    calling_targets_ch = Channel.value(file(params.calling_targets, checkIfExists: true))
    coverage_targets_ch = Channel.value(file(params.coverage_targets, checkIfExists: true))
    bqsr_sites_ch = Channel.value(tuple(file(params.dbsnp, checkIfExists: true), file(params.dbsnp_index, checkIfExists: true), file(params.known_indels, checkIfExists: true), file(params.known_indels_index, checkIfExists: true), file(params.mills_indels, checkIfExists: true), file(params.mills_indels_index, checkIfExists: true)))
    somatic_resources_ch = Channel.value(tuple(file(params.germline_resource, checkIfExists: true), file(params.germline_resource_index, checkIfExists: true), file(params.panel_of_normals, checkIfExists: true), file(params.panel_of_normals_index, checkIfExists: true)))
    contamination_sites_ch = Channel.value(tuple(file(params.contamination_sites, checkIfExists: true), file(params.contamination_sites_index, checkIfExists: true)))

    reference_file = file(params.reference, checkIfExists: true)
    bwa_paths = ['amb', 'ann', 'bwt', 'pac', 'sa'].collect { "${params.reference}.${it}" }
    if (bwa_paths.every { file(it).exists() }) {
        log.info 'Existing complete BWA index found; BWA_INDEX will be skipped.'
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
    } else {
        log.info 'Complete BWA index not found; running BWA_INDEX.'
        BWA_INDEX(Channel.value(reference_file))
        bwa_index_ch = BWA_INDEX.out.index
    }

    ALIGN_BWA(FASTP.out.reads, bwa_index_ch)
    SAMTOOLS_QC_PREDUP(ALIGN_BWA.out.bam)
    MARK_DUPLICATES(ALIGN_BWA.out.bam)
    SAMTOOLS_QC_POSTDUP(MARK_DUPLICATES.out.bam)
    BASE_RECALIBRATOR(MARK_DUPLICATES.out.bam, gatk_ref_ch, bqsr_sites_ch)
    APPLY_BQSR(BASE_RECALIBRATOR.out.recalibration, gatk_ref_ch)
    MOSDEPTH(APPLY_BQSR.out.bam, coverage_targets_ch)
    GET_PILEUP_SUMMARIES(APPLY_BQSR.out.bam, gatk_ref_ch, contamination_sites_ch, calling_targets_ch)

    tumor_bam_ch = APPLY_BQSR.out.bam.filter { pair_id, sample_id, role, bam, bai -> role == 'tumor' }.map { pair_id, sample_id, role, bam, bai -> tuple(pair_id, sample_id, bam, bai) }
    normal_bam_ch = APPLY_BQSR.out.bam.filter { pair_id, sample_id, role, bam, bai -> role == 'normal' }.map { pair_id, sample_id, role, bam, bai -> tuple(pair_id, sample_id, bam, bai) }
    matched_bams_ch = tumor_bam_ch.join(normal_bam_ch, by: 0)

    tumor_pileups_ch = GET_PILEUP_SUMMARIES.out.pileups.filter { pair_id, sample_id, role, table -> role == 'tumor' }.map { pair_id, sample_id, role, table -> tuple(pair_id, sample_id, table) }
    normal_pileups_ch = GET_PILEUP_SUMMARIES.out.pileups.filter { pair_id, sample_id, role, table -> role == 'normal' }.map { pair_id, sample_id, role, table -> tuple(pair_id, sample_id, table) }
    matched_pileups_ch = tumor_pileups_ch.join(normal_pileups_ch, by: 0)

    MUTECT2(matched_bams_ch, gatk_ref_ch, somatic_resources_ch, calling_targets_ch)
    LEARN_READ_ORIENTATION_MODEL(MUTECT2.out.f1r2)
    CALCULATE_CONTAMINATION(matched_pileups_ch)

    orientation_ch = LEARN_READ_ORIENTATION_MODEL.out.model.map { pair_id, tumor_id, normal_id, model -> tuple(pair_id, model) }
    contamination_ch = CALCULATE_CONTAMINATION.out.tables.map { pair_id, tumor_id, normal_id, table, segments -> tuple(pair_id, table, segments) }
    filter_input_ch = MUTECT2.out.variants.join(orientation_ch, by: 0).join(contamination_ch, by: 0)
    FILTER_MUTECT_CALLS(filter_input_ch, gatk_ref_ch)

    if (params.run_vep) {
        VEP(FILTER_MUTECT_CALLS.out.filtered, Channel.value(file(params.vep_cache, checkIfExists: true)))
        final_variants_ch = VEP.out.annotated
    } else {
        final_variants_ch = FILTER_MUTECT_CALLS.out.filtered
    }
    VCF_TO_TSV(final_variants_ch)

    if (params.run_cnv) {
        CNVKIT(matched_bams_ch, gatk_ref_ch, calling_targets_ch)
        CNVKIT_CALL(CNVKIT.out.segments)
        CNV_TO_TSV(CNVKIT_CALL.out.calls)

        if (params.cnv_gene_annotation) {
            ANNOTATE_CNV_GENES(
                CNVKIT_CALL.out.calls,
                Channel.value(file(params.cnv_gene_annotation, checkIfExists: true))
            )
        }
    }
    if (params.run_germline) {
        normal_for_germline_ch = normal_bam_ch.map { pair_id, normal_id, bam, bai -> tuple(pair_id, normal_id, bam, bai) }
        HAPLOTYPE_CALLER(normal_for_germline_ch, gatk_ref_ch, calling_targets_ch)
        GENOTYPE_GVCFS(HAPLOTYPE_CALLER.out.gvcf, gatk_ref_ch, calling_targets_ch)
        NORMALIZE_GERMLINE_VARIANTS(GENOTYPE_GVCFS.out.variants, Channel.value(reference_file))
        FILTER_GERMLINE_VARIANTS(NORMALIZE_GERMLINE_VARIANTS.out.normalized, gatk_ref_ch)

        if (params.run_vep) {
            VEP_GERMLINE(
                FILTER_GERMLINE_VARIANTS.out.filtered,
                Channel.value(file(params.vep_cache, checkIfExists: true))
            )
            final_germline_variants_ch = VEP_GERMLINE.out.annotated
        } else {
            final_germline_variants_ch = FILTER_GERMLINE_VARIANTS.out.filtered
        }

        GERMLINE_VCF_TO_TSV(final_germline_variants_ch)
    }

    raw_fastqc_files_ch = FASTQC_RAW.out.reports.map { pair_id, sample_id, html, zip -> [html, zip] }
    fastp_report_files_ch = FASTP.out.reports.map { pair_id, sample_id, html, json -> [html, json] }
    trimmed_fastqc_files_ch = FASTQC_TRIMMED.out.reports.map { pair_id, sample_id, html, zip -> [html, zip] }
    predup_report_files_ch = SAMTOOLS_QC_PREDUP.out.reports.map { pair_id, sample_id, flagstat, idxstats, stats -> [flagstat, idxstats, stats] }
    duplicate_metric_files_ch = MARK_DUPLICATES.out.metrics.map { pair_id, sample_id, metrics -> metrics }
    postdup_report_files_ch = SAMTOOLS_QC_POSTDUP.out.reports.map { pair_id, sample_id, flagstat, idxstats, stats -> [flagstat, idxstats, stats] }
    coverage_report_files_ch = MOSDEPTH.out.coverage.map { pair_id, sample_id, role, summary, global_dist, regions, regions_index -> [summary, global_dist, regions, regions_index] }

    qc_files_ch = raw_fastqc_files_ch
        .mix(fastp_report_files_ch, trimmed_fastqc_files_ch, predup_report_files_ch, duplicate_metric_files_ch, postdup_report_files_ch, coverage_report_files_ch)
        .flatten()
        .collect()
    MULTIQC(qc_files_ch)
}
