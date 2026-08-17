# WES tumor-normal Nextflow

Workflow Nextflow DSL2 reproducible para analizar múltiples parejas tumor-normal de exoma completo (WES). Cada paciente se identifica mediante `pair_id`; el workflow exige exactamente una muestra `tumor` y una muestra `normal` por pareja y nunca combina muestras de pacientes diferentes.

## Alcance

Flujo principal:

1. FastQC de lecturas originales.
2. Recorte y control de calidad con fastp.
3. FastQC de lecturas recortadas.
4. Alineamiento contra GRCh38 con BWA-MEM y ordenación con samtools.
5. Marcado, no eliminación, de duplicados.
6. BQSR con GATK.
7. Cobertura sobre las regiones capturadas con mosdepth.
8. Mutect2 tumor-normal restringido al diseño de captura.
9. Modelo de artefactos de orientación F1R2.
10. Estimación de contaminación con la muestra normal emparejada.
11. FilterMutectCalls.
12. Conversión del VCF filtrado a TSV y resumen de QC con MultiQC.

Ramas opcionales: CNVkit, VEP y HaplotypeCaller sobre la muestra normal.

> Este pipeline es apropiado para investigación. No constituye por sí solo un procedimiento clínico validado. Los resultados dependen del diseño de captura, calidad, profundidad, pureza tumoral, ploidía y compatibilidad exacta de todos los recursos con GRCh38.

## Estructura del proyecto

```text
WES-tumor-normal-nextflow/
├── main.nf
├── nextflow.config
├── samplesheet.csv
├── bin/
├── envs/
├── data/
└── reference/
    ├── Homo_sapiens_assembly38.fasta
    ├── Homo_sapiens_assembly38.fasta.fai
    ├── Homo_sapiens_assembly38.dict
    ├── intervals/exome_targets.hg38.bed
    ├── known_sites/
    └── somatic/
```

Los FASTQ, referencias, índices, `work/` y `results/` no deben subirse a GitHub.

## Samplesheet para múltiples pacientes

```csv
pair_id,sample,role,fastq_1,fastq_2
P1,SRR7890883,tumor,/ruta/SRR7890883_1.fastq.gz,/ruta/SRR7890883_2.fastq.gz
P1,SRR7890874,normal,/ruta/SRR7890874_1.fastq.gz,/ruta/SRR7890874_2.fastq.gz
P2,TUMOR_02,tumor,/ruta/TUMOR_02_R1.fastq.gz,/ruta/TUMOR_02_R2.fastq.gz
P2,NORMAL_02,normal,/ruta/NORMAL_02_R1.fastq.gz,/ruta/NORMAL_02_R2.fastq.gz
```

Reglas:

- `pair_id` vincula tumor y normal del mismo paciente.
- Cada `pair_id` debe aparecer exactamente dos veces: una como `tumor` y otra como `normal`.
- `sample` debe ser único en toda la cohorte y coincidir con el nombre de muestra usado en el read group del BAM.
- Use identificadores simples, sin espacios ni caracteres de shell.
- Las rutas pueden ser absolutas o relativas al directorio desde el que se ejecuta Nextflow.

## Recursos obligatorios

Todos los recursos deben usar la misma referencia y nomenclatura de contigs (aquí, GRCh38). No mezcle `chr1` con `1`, ni recursos hg19 con GRCh38.

| Parámetro | Recurso |
|---|---|
| `--reference` | FASTA GRCh38 |
| `--reference_fai` | índice samtools `.fai` |
| `--reference_dict` | diccionario GATK/Picard `.dict` |
| `--targets` | BED del kit de captura de exoma realmente usado |
| `--dbsnp` | dbSNP para BQSR y su `.idx` |
| `--known_indels` | indels conocidos y `.tbi` |
| `--mills_indels` | Mills indels y `.tbi` |
| `--germline_resource` | recurso af-only gnomAD y `.tbi` para Mutect2 |
| `--panel_of_normals` | panel de normales y `.tbi` |
| `--contamination_sites` | VCF pequeño de SNP comunes y `.tbi` para GetPileupSummaries |

El archivo `reference/intervals/exome_targets.hg38.bed` **no puede reemplazarse por un BED genérico**: debe corresponder al kit de captura y a GRCh38. Si se desconoce el kit, confírmelo en los metadatos del estudio o del centro de secuenciación antes de interpretar cobertura, variantes o CNV.

Los archivos `.fai`, `.dict`, `.idx` y `.tbi` son índices; no son copias de la referencia. Deben corresponder exactamente al archivo principal que acompañan.

### Índice BWA

Se utiliza BWA clásico, no BWA-MEM2, para reducir el pico de memoria durante la indexación de GRCh38. Si existen los cinco archivos `.amb`, `.ann`, `.bwt`, `.pac` y `.sa`, el proceso `BWA_INDEX` se omite incluso sin `-resume`. Si falta cualquiera, se reconstruye el conjunto completo.

## Entornos reproducibles

El archivo `nextflow.config` asigna un entorno Conda pequeño a cada familia de herramientas. Esto evita el conflicto de dependencias que puede aparecer al forzar BWA, GATK, bcftools, CNVkit y VEP dentro de un único YAML exportado.

Instale Nextflow y Conda/Mamba, dé permisos a los scripts y ejecute:

```bash
cd /home/paula-di-santo/Documents/GitHub_projects/WES-tumor-normal-nextflow
chmod +x bin/*.sh
nextflow run main.nf -profile conda -resume
```

Para usar rutas distintas:

```bash
nextflow run main.nf -profile conda -resume \
  --input /ruta/samplesheet.csv \
  --reference /ruta/Homo_sapiens_assembly38.fasta \
  --reference_fai /ruta/Homo_sapiens_assembly38.fasta.fai \
  --reference_dict /ruta/Homo_sapiens_assembly38.dict \
  --targets /ruta/targets_del_kit.hg38.bed \
  --outdir /ruta/results
```

`-resume` reutiliza tareas válidas del directorio `work/`. Es recomendable para continuar una corrida interrumpida, pero no reemplaza un respaldo de los resultados.

## Ramas opcionales

### CNV somáticas

```bash
nextflow run main.nf -profile conda -resume --run_cnv true
```

CNVkit usa el tumor y su normal emparejado. En WES, la resolución y exactitud de CNV son limitadas y dependen fuertemente de cobertura, pureza, ploidía y diseño de captura.

### Variantes germinales de las muestras normales

```bash
nextflow run main.nf -profile conda -resume --run_germline true
```

Esta rama produce un gVCF por normal mediante HaplotypeCaller. Los gVCF no son todavía una llamada conjunta de cohorte; para ello se requiere GenomicsDBImport/GenotypeGVCFs y filtrado germinal posterior.

### Anotación con VEP

```bash
nextflow run main.nf -profile conda -resume \
  --run_vep true \
  --vep_cache /ruta/al/cache/VEP
```

La caché debe estar instalada localmente para *Homo sapiens*, GRCh38, y ser compatible con la versión de VEP fijada en `envs/vep.yml`.

## Resultados principales

- `results/multiqc/multiqc_report.html`: resumen global de QC.
- `results/pipeline_info/`: informe, cronología y tabla de trazabilidad de Nextflow.
- `results/coverage/`: cobertura por muestra y regiones objetivo.
- `results/contamination/`: pileups, contaminación y segmentación.
- `results/mutect2/<pair_id>/*.unfiltered.vcf.gz`: llamadas sin filtrar.
- `results/mutect2/<pair_id>/*.filtered.vcf.gz`: llamadas evaluadas por FilterMutectCalls.
- `results/mutect2/<pair_id>/*.final.tsv`: tabla legible; conserva la columna `FILTER`.
- `results/cnvkit/<pair_id>/`: resultados CNV opcionales.
- `results/germline/<pair_id>/`: gVCF opcionales de las muestras normales.

Una variante presente en el VCF “filtered” no necesariamente tiene `PASS`; revise siempre la columna `FILTER`. Para informes biológicos también hacen falta anotación, controles de calidad, revisión visual y criterios definidos previamente.

## Consideraciones de recursos

El proceso Mutect2 solicita 24 GB de RAM y se limita a una pareja simultánea (`maxForks 1`), adecuado para una estación con unos 32 GB de RAM. Los procesos de muestras distintas se paralelizan cuando los recursos lo permiten. Ajuste `cpus`, `memory` y `maxForks` a su equipo o clúster.

Para un análisis real use los FASTQ completos. Submuestras pequeñas sirven para comprobar que el pipeline funciona, pero no permiten inferencias fiables sobre sensibilidad, ausencia de variantes, cobertura ni CNV.

## Documentación científica y técnica

- [GATK FilterMutectCalls](https://gatk.broadinstitute.org/hc/en-us/articles/9570331605531-FilterMutectCalls)
- [GATK CalculateContamination](https://gatk.broadinstitute.org/hc/en-us/articles/4414586751771-CalculateContamination)
- [GATK LearnReadOrientationModel](https://gatk.broadinstitute.org/hc/en-us/articles/13832692984347-LearnReadOrientationModel)
- [CNVkit pipeline](https://cnvkit.readthedocs.io/en/stable/pipeline.html)
- [Ensembl VEP cache](https://www.ensembl.org/info/docs/tools/vep/script/vep_cache.html)
