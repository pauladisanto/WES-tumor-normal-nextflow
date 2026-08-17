process BWA_INDEX {
    label 'alignment'
    tag "${reference.simpleName}"
    cpus 1; memory '10 GB'; time '12h'; maxForks 1
    publishDir "${projectDir}/reference", mode: 'copy', overwrite: false, pattern: '*.amb'
    publishDir "${projectDir}/reference", mode: 'copy', overwrite: false, pattern: '*.ann'
    publishDir "${projectDir}/reference", mode: 'copy', overwrite: false, pattern: '*.bwt'
    publishDir "${projectDir}/reference", mode: 'copy', overwrite: false, pattern: '*.pac'
    publishDir "${projectDir}/reference", mode: 'copy', overwrite: false, pattern: '*.sa'
    input:
    path reference
    output:
    tuple path(reference), path("${reference}.amb"), path("${reference}.ann"), path("${reference}.bwt"), path("${reference}.pac"), path("${reference}.sa"), emit: index
    script:
    "wes_bwa_index.sh ${reference}"
}
