"""
This rule uses Samtools to perform fix mate operation on
BWA output. It does not use any wrapper since (1) it does
not exists, and (2) co-workers are currently writing the
wrapper
"""
rule samtools_fixmate:
    input:
        "bwa/mapping/{sample}.bam"
    output:
        temp("samtools/fixmate/{sample}.bam")
    message:
        "Fixing mates in BWA's output"
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
        extra = config["samtools_fixmate_extra"]
    shell:
        "samtool fixmate "  # Tool
        "-c "               # Add template cigar
        "-m "               # Add mate score tag
        "{input} "          # Path to input file
        "{output} "         # Path to output file
        " > {log} 2>&1"     # Logging
