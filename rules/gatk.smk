"""
This rule performs both BQSR table computation and its
application to the original input bam file
"""
rule gatk_bqsr:
    input:
        bam = "picard/deduplicated/{sample}.bam",
        ref = refs_pack_dict["fasta"],
        known = refs_pack_dict["known_vcf"]
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
            lambda wildcards, attempt: min(attempt * 2048, 7168, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 75, 240)
        )
    log:
        "logs/gatk/bqsr/{sample}.log"
    params:
        java_opts = (
            lambda wildcards, resources: "-Djava.io.tmpdir=tmp/JAVA_TMP_{wildcards['sample']} -Xmx{resources['mem_mb']}m"
        ),
        extra = (
            lambda wildcards:            "{config['params']['gatk_bqsr_extra']} --tmp-dir TMP_BQSR_{wildcards.sample}"
        )
    wrapper:
        f"{swv}/bio/gatk/baserecalibrator"
