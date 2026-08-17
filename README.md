# WES Tumor-Normal Nextflow

A reproducible Nextflow DSL2 workflow for analyzing multiple whole-exome sequencing (WES) tumor-normal pairs. Each patient is identified by a `pair_id`. The workflow requires exactly one `tumor` sample and one `normal` sample per pair and prevents samples from different patients from being combined.

## Scope

Main workflow:

1. FastQC on raw reads.
2. Read trimming and quality control with fastp.
3. FastQC on trimmed reads.
4. Alignment to GRCh38 with BWA-MEM and sorting with samtools.
5. Duplicate marking without duplicate removal.
6. Base quality score recalibration (BQSR) with GATK.
7. Coverage analysis over captured regions with mosdepth.
8. Tumor-normal variant calling with Mutect2, restricted to the capture design.
9. F1R2 read-orientation artifact modeling.
10. Contamination estimation using the matched normal sample.
11. Variant filtering with FilterMutectCalls.
12. Conversion of the filtered VCF to TSV and generation of a MultiQC report.

Optional branches include CNVkit, VEP, and HaplotypeCaller on the normal sample.

> This pipeline is intended for research use. It is not, by itself, a clinically validated procedure. Results depend on the capture design, sample quality, sequencing depth, tumor purity, ploidy, and exact compatibility of all resources with GRCh38.

## Project structure

```text
WES-tumor-normal-nextflow/
├── main.nf
├── nextflow.config
├── samplesheet.csv
├── modules/
├── bin/
├── envs/
├── data/
└── reference/
    ├── Homo_sapiens_assembly38.fasta
    ├── Homo_sapiens_assembly38.fasta.fai
    ├── Homo_sapiens_assembly38.dict
    ├── intervals/
    │   └── agilent_v6_utr/
    │       └── S07604624_hg38/
    │           ├── S07604624_Regions.bed
    │           └── S07604624_Covered.bed
    ├── known_sites/
    └── somatic/
```

FASTQ files, reference resources, indexes, `work/`, and `results/` should not be committed to GitHub.

## Samplesheet for multiple patients

```csv
pair_id,sample,role,fastq_1,fastq_2
P1,SRR7890883,tumor,/path/to/SRR7890883_1.fastq.gz,/path/to/SRR7890883_2.fastq.gz
P1,SRR7890874,normal,/path/to/SRR7890874_1.fastq.gz,/path/to/SRR7890874_2.fastq.gz
P2,TUMOR_02,tumor,/path/to/TUMOR_02_R1.fastq.gz,/path/to/TUMOR_02_R2.fastq.gz
P2,NORMAL_02,normal,/path/to/NORMAL_02_R1.fastq.gz,/path/to/NORMAL_02_R2.fastq.gz
```

Rules:

- `pair_id` links the tumor and normal samples from the same patient.
- Each `pair_id` must appear exactly twice: once as `tumor` and once as `normal`.
- `sample` must be unique across the cohort and must match the sample name used in the BAM read group.
- Use simple identifiers without spaces or shell-sensitive characters.
- Paths may be absolute or relative to the directory from which Nextflow is launched.

## Required resources

All resources must use the same reference assembly and contig naming convention. Do not mix `chr1` with `1`, or hg19 resources with GRCh38.

| Parameter | Resource |
|---|---|
| `--reference` | GRCh38 FASTA |
| `--reference_fai` | samtools `.fai` index |
| `--reference_dict` | GATK/Picard `.dict` sequence dictionary |
| `--calling_targets` | GRCh38 BED containing the biological target regions used for variant calling |
| `--coverage_targets` | GRCh38 BED containing regions covered by the capture probes |
| `--targets` | Compatibility alias for older `main.nf` versions that still use a single target BED |
| `--dbsnp` | dbSNP resource for BQSR, with its `.idx` index |
| `--known_indels` | Known indels resource, with its `.tbi` index |
| `--mills_indels` | Mills indels resource, with its `.tbi` index |
| `--germline_resource` | af-only gnomAD resource for Mutect2, with its `.tbi` index |
| `--panel_of_normals` | Panel of normals, with its `.tbi` index |
| `--contamination_sites` | Common-SNP VCF for GetPileupSummaries, with its `.tbi` index |

The target BED files cannot be replaced with arbitrary generic exome intervals. They must correspond to the capture kit that was actually used and to GRCh38. For the Agilent SureSelect Human All Exon V6+UTR design used here:

- `S07604624_Regions.bed` contains the target regions of interest and is used for variant calling.
- `S07604624_Covered.bed` contains regions covered by the capture probes and is used for coverage analysis and CNVkit.

If the capture kit is unknown, confirm it using the study metadata or information from the sequencing center before interpreting coverage, variants, or copy-number changes.

The `.fai`, `.dict`, `.idx`, and `.tbi` files are indexes, not copies of their corresponding resources. Each index must match its associated primary file exactly.

### BWA index

The workflow uses classic BWA rather than BWA-MEM2 to reduce peak memory usage while indexing GRCh38. If all five index files (`.amb`, `.ann`, `.bwt`, `.pac`, and `.sa`) are present, `BWA_INDEX` is skipped even without `-resume`. If any index file is missing, the complete index set is rebuilt.

## Reproducible environments

The `nextflow.config` file assigns a small Conda environment to each tool family. This avoids dependency conflicts that can occur when BWA, GATK, bcftools, CNVkit, and VEP are forced into a single exported YAML environment.

Install Nextflow and Conda or Mamba, make the scripts executable, and launch the workflow:

```bash
cd /path/to/WES-tumor-normal-nextflow
chmod +x bin/*.sh
nextflow run main.nf -profile conda -resume
```

To use custom paths:

```bash
nextflow run main.nf -profile conda -resume \
  --input /path/to/samplesheet.csv \
  --reference /path/to/Homo_sapiens_assembly38.fasta \
  --reference_fai /path/to/Homo_sapiens_assembly38.fasta.fai \
  --reference_dict /path/to/Homo_sapiens_assembly38.dict \
  --calling_targets /path/to/capture_kit_regions.hg38.bed \
  --coverage_targets /path/to/capture_kit_covered.hg38.bed \
  --targets /path/to/capture_kit_regions.hg38.bed \
  --outdir /path/to/results
```

`-resume` reuses valid tasks from the `work/` directory. It is recommended when continuing an interrupted run, but it is not a substitute for backing up final results.

## Optional branches

### Somatic copy-number variants

```bash
nextflow run main.nf -profile conda -resume --run_cnv true
```

CNVkit uses each tumor and its matched normal sample. Copy-number resolution and accuracy in WES data are limited and depend strongly on coverage, tumor purity, ploidy, and capture design.

### Germline variants in normal samples

```bash
nextflow run main.nf -profile conda -resume --run_germline true
```

This branch produces one gVCF per normal sample with HaplotypeCaller. These gVCFs do not constitute joint cohort genotyping. Joint genotyping requires subsequent GenomicsDBImport, GenotypeGVCFs, and germline filtering steps.

### VEP annotation

```bash
nextflow run main.nf -profile conda -resume \
  --run_vep true \
  --vep_cache /path/to/vep/cache
```

The cache must be installed locally for *Homo sapiens*, GRCh38, and must be compatible with the VEP version specified in `envs/vep.yml`.

## Main outputs

- `results/multiqc/multiqc_report.html`: global quality-control summary.
- `results/pipeline_info/`: Nextflow execution report, timeline, and trace table.
- `results/coverage/`: sample-level and target-region coverage results.
- `results/contamination/`: pileup, contamination, and segmentation results.
- `results/mutect2/<pair_id>/*.unfiltered.vcf.gz`: unfiltered somatic calls.
- `results/mutect2/<pair_id>/*.filtered.vcf.gz`: calls evaluated by FilterMutectCalls.
- `results/mutect2/<pair_id>/*.final.tsv`: readable variant table retaining the `FILTER` column.
- `results/cnvkit/<pair_id>/`: optional CNVkit results.
- `results/germline/<pair_id>/`: optional gVCFs from normal samples.

A variant present in a filtered VCF does not necessarily have a `PASS` status. Always inspect the `FILTER` column. Biological reporting also requires annotation, quality controls, visual inspection, and predefined interpretation criteria.

## Resource considerations

Mutect2 requests 24 GB of RAM and is limited to one pair at a time with `maxForks 1`, which is appropriate for a workstation with approximately 32 GB of RAM. Processes for different samples are parallelized when resources permit. Adjust `cpus`, `memory`, and `maxForks` for the available workstation or compute cluster.

Use complete FASTQ files for real analyses. Small subsamples are useful for testing whether the pipeline runs, but they cannot support reliable conclusions about sensitivity, absence of variants, coverage, or copy-number changes.

## Scientific and technical documentation

- [GATK FilterMutectCalls](https://gatk.broadinstitute.org/hc/en-us/articles/9570331605531-FilterMutectCalls)
- [GATK CalculateContamination](https://gatk.broadinstitute.org/hc/en-us/articles/4414586751771-CalculateContamination)
- [GATK LearnReadOrientationModel](https://gatk.broadinstitute.org/hc/en-us/articles/13832692984347-LearnReadOrientationModel)
- [CNVkit pipeline](https://cnvkit.readthedocs.io/en/stable/pipeline.html)
- [Ensembl VEP cache](https://www.ensembl.org/info/docs/tools/vep/script/vep_cache.html)
