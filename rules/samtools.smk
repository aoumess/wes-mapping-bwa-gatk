"""
This rule sorts reads by name for fixmate
"""
rule samtools_sort_query:
    input:
        "bwa/mapping/{sample}.bam"
    output:
        temp("samtools/query_sort/{sample}.bam")
    message:
        "Sorting {wildcards.sample} reads by query name for fixing mates"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 24576)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 75, 225)
        )
    log:
        "logs/samtools/query_sort_{sample}.log"
    params:
        "-m 8G -n"
    wrapper:
        f"{swv}/bio/samtools/sort"

"""
This rule uses Samtools to perform fix mate operation on
BWA output. It does not use any wrapper since (1) it does
not exists, and (2) co-workers are currently writing the
wrapper
"""
rule samtools_fixmate:
    input:
        "samtools/query_sort/{sample}.bam"
    output:
        temp("samtools/fixmate/{sample}.bam")
    message:
        "Fixing mates in {wildcards.sample} BWA's output"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048 + 2048, 8192)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 180)
        )
    version: "1.0"
    conda:
        "../envs/samtools.yaml"
    log:
        "logs/samtools/fixmate_{sample}.log"
    params:
        extra = config["params"]["samtools_fixmate_extra"]
    shell:
        "mkdir --parents --verbose samtools/fixmate/ "  # Building output dir
        "&& samtools fixmate "  # Tool
        " {params.extra} "     # Add extra parameters
        "{input} "             # Path to input file
        "{output} "            # Path to output file
        " > {log} 2>&1"        # Logging

"""
This rule sorts reads by position for further analyses
"""
rule samtools_sort_coordinate:
    input:
        "samtools/fixmate/{sample}.bam"
    output:
        temp("samtools/position_sort/{sample}.bam")
    message:
        "Sorting {wildcards.sample} reads by query name for fixing mates"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 24576)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 75, 225)
        )
    log:
        "logs/samtools/query_sort_{sample}.log"
    params:
        "-m 8G"
    wrapper:
        f"{swv}/bio/samtools/sort"
