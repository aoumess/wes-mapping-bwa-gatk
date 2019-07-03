"""
This rule performs both BQSR table computation and its
application to the original input bam file
"""
rule gatk_bqsr:
    input:
        bam = "picard/deduplicated/{sample}.bam",
        ref = refs_pack_dict["fasta"],
        ref_index = refs_pack_dict["faidx"],
        ref_dict = refs_pack_dict["fadict"],
        known = refs_pack_dict["known_vcf"],
        known_index = refs_pack_dict["known_index"]
    output:
        bam = report(
            "gatk/recal/{sample}.bam",
            caption="../report/gatk.rst",
            category="Mapping"
        )
    message:
        "Recalibrating variants in {wildcards.sample} with GATK"
    threads:
        1
    version:
        swv
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048 + 7168, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 75, 240)
        )
    log:
        "logs/gatk/bqsr/{sample}.log"
    params:
        java_opts = (
            lambda wildcards, resources: get_java_args(wildcards, resources)
        ),
        extra = (
            lambda wildcards: get_gatk_args(wildcards)
        )
    wrapper:
        f"{swv}/bio/gatk/baserecalibrator"
