# WES Tumor-Normal Nextflow Workflow

A modular Nextflow DSL2 workflow for paired-end whole-exome sequencing (WES) of matched tumor-normal samples.

The workflow performs read quality control, alignment to GRCh38, BAM preprocessing, somatic variant calling with GATK Mutect2, filtering, and summary reporting. Optional branches are available for germline variants, copy-number alterations, and VEP annotation.

> This workflow is intended for research and technical evaluation. It is not validated for clinical diagnosis.

## Workflow overview

### Main analysis

1. **FastQC** on raw FASTQ files
2. **fastp** adapter trimming and read filtering
3. **FastQC** on trimmed FASTQ files
4. **BWA** alignment to GRCh38
5. **samtools** alignment quality control
6. **Picard MarkDuplicates**
7. **GATK BaseRecalibrator and ApplyBQSR**
8. **Mosdepth** coverage calculation over the capture regions
9. **GATK GetPileupSummaries** and contamination estimation
10. **GATK Mutect2** somatic SNV and indel calling
11. Orientation-bias and contamination-aware filtering
12. Optional **VEP** annotation
13. Conversion of the final VCF to TSV
14. **MultiQC** report generation

### Optional analyses

- **CNVkit** for tumor-normal copy-number analysis
- **HaplotypeCaller** for germline variant calling in the matched normal
- **VEP** annotation for somatic and germline variants
- **GENCODE/Ensembl GTF** overlap annotation for CNV segments

## Requirements

- Linux
- Nextflow `>=25.04.0`
- Conda or Mamba
- Sufficient storage for FASTQ, BAM, reference, cache, and work files

The software used by individual processes is defined in the YAML files under `envs/`. Nextflow creates and reuses separate Conda environments according to the process labels in `nextflow.config`.

## Input samplesheet

The workflow expects a CSV file with one tumor and one matched normal for each `pair_id`:

```csv
pair_id,sample,role,fastq_1,fastq_2
P1,SRR7890883,tumor,/path/to/SRR7890883_1.fastq.gz,/path/to/SRR7890883_2.fastq.gz
P1,SRR7890874,normal,/path/to/SRR7890874_1.fastq.gz,/path/to/SRR7890874_2.fastq.gz
```

Required columns:

| Column | Description |
|---|---|
| `pair_id` | Identifier shared by the matched tumor and normal |
| `sample` | Globally unique sample identifier |
| `role` | Either `tumor` or `normal` |
| `fastq_1` | Path to read 1 FASTQ |
| `fastq_2` | Path to read 2 FASTQ |

The workflow checks that every pair contains exactly one tumor and one normal and that sample identifiers are unique.

## Reference files

Reference paths are configured in `nextflow.config`. The current setup uses:

- GRCh38 FASTA, `.fai`, and sequence dictionary
- Agilent SureSelect V6 + UTR target intervals
- dbSNP, known indels, and Mills/1000G indels for BQSR
- gnomAD allele frequencies and a panel of normals for Mutect2
- common population sites for contamination estimation
- optional VEP cache for GRCh38
- optional GENCODE or Ensembl GTF for CNV-gene overlaps

Two BED files have different purposes:

- `calling_targets`: regions used for variant calling, contamination analysis, and CNV analysis
- `coverage_targets`: regions used by Mosdepth to report capture-region coverage

Large reference resources and the VEP cache should not be committed to Git.

## Running the workflow

### Core somatic workflow

```bash
NXF_CONDA_CACHEDIR="$PWD/work/conda" \
nextflow run main.nf \
    -profile conda \
    -resume
```

The default input and output paths are defined in `nextflow.config`. They can also be supplied on the command line:

```bash
nextflow run main.nf \
    -profile conda \
    -resume \
    --input "$PWD/samplesheet.csv" \
    --outdir "$PWD/results"
```

### Run all optional branches

```bash
NXF_CONDA_CACHEDIR="$PWD/work/conda" \
nextflow run main.nf \
    -profile conda \
    -resume \
    --run_cnv true \
    --run_germline true \
    --run_vep true \
    --cnv_gene_annotation "$PWD/reference/annotation/gencode.v46.annotation.gtf.gz" \
    -with-dag "$PWD/workflow_dag.html"
```

The optional branches are disabled by default.

| Parameter | Default | Description |
|---|---:|---|
| `--run_cnv` | `false` | Run CNVkit on the tumor-normal pair |
| `--run_germline` | `false` | Call germline variants in the normal sample |
| `--run_vep` | `false` | Annotate somatic and germline VCF files with VEP |
| `--cnv_gene_annotation` | `null` | Optional GTF/GTF.GZ for CNV-gene overlaps |

## VEP cache

VEP runs offline and requires a local Homo sapiens GRCh38 cache compatible with VEP release 112. One installation method is:

```bash
conda env create -f envs/vep.yml
conda activate wes-vep

mkdir -p reference/vep_cache

vep_install \
    --AUTO cf \
    --SPECIES homo_sapiens \
    --ASSEMBLY GRCh38 \
    --CACHE_VERSION 112 \
    --CACHEDIR "$PWD/reference/vep_cache"
```

## Main outputs

Outputs are written under the directory specified by `--outdir`.

| Output | Description |
|---|---|
| Recalibrated BAM and BAI | Final processed alignments for each sample |
| `*.unfiltered.vcf.gz` | Candidate somatic variants from Mutect2 |
| `*.filtered.vcf.gz` | Filtered somatic variants |
| `*.annotated.vcf.gz` | VEP-annotated variants when enabled |
| `*.final.tsv` | Tab-separated variant summary |
| `*.germline.filtered.vcf.gz` | Filtered germline variants when enabled |
| `*.cnv.cnr` and `*.cns` | CNVkit bin-level and segmented copy-number results |
| `*.cnv.final.tsv` | Copy-number summary table |
| `multiqc_report.html` | Combined quality-control report |
| `pipeline_info/` | Nextflow report, timeline, and trace files |

FastQC results from raw and trimmed reads are included in MultiQC. Their names should contain `raw` or `trimmed` so the two stages remain distinguishable in the combined report.

## Resume and cleanup

Use `-resume` to reuse successfully completed tasks:

```bash
nextflow run main.nf -profile conda -resume
```

Nextflow stores intermediate files under `work/`. Input files appearing there are often symbolic links, while process outputs occupy real disk space. After confirming that all required results were published, unused work files can be removed with:

```bash
nextflow clean -f
```

Use cleanup carefully because removed intermediate files can no longer be reused with `-resume`.

## Notes

- The workflow is designed for paired tumor-normal WES data.
- Capture intervals must match the library preparation kit and the GRCh38 reference.
- A `PASS` filter indicates that a variant passed the implemented technical filters; it does not establish clinical relevance.
- Candidate variants should be reviewed together with coverage, allele depth, population frequency, annotation, and supporting reads.

