"""
This rule uses BWA to index a fasta formatted genome sequence
"""
rule bwa_index:
    input:
        **refs_pack_dict
    output:
        expand(
            "bwa/index/{genome}.{ext}",
            genome=refs_pack_dict["fasta"],
            ext=["amb", "ann", "bwt", "pac", "sa"]
        )
    message:
        "Indexing {input.fasta} with BWA"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 240)
        )
    version: swv
    log:
        "logs/bwa/index.log"
    params:
        prefix = f"bwa/index/{refs_pack_dict['fasta']}"
    wrapper:
        f"{swv}/bio/bwa/index"


"""
This rule performs the actual bwa mem mapping
"""
rule bwa_mem:
    input:
        unpack(fq_pairs_w),
        index = expand(
            "bwa/index/{genome}.{ext}",
            genome=refs_pack_dict["fasta"],
            ext=["amb", "ann", "bwt", "pac", "sa"]
        )
    output:
        report(
            temp("bwa/mapping/{sample}.bam"),
            caption="../report/bwa.rst",
            category="Mapping"
        )
    message:
        "Mapping {wildcards.sample} with BWA mem"
    threads:
        min(config["threads"], 12)
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 240)
        )
    version: swv
    params:
        index = "{input.index}",
        extra = config['params']['bwa_map_extra'],
        sort = "picard",
        sort_order = "coordinate",
        sort_extra = config['params']['picard_sort_sam_extra']
    log:
        "logs/bwa_mem_{sample}.log"
    wrapper:
        f"{swv}/bio/bwa/mem"
