"""
While other .smk files contains rules and pure snakemake instructions, this
one gathers all the python instructions surch as config mappings or input
validations.
"""

from snakemake.utils import validate, makedirs
from typing import Any, Dict, List

import os.path as op    # Path and file system manipulation
import os               # OS related operations
import pandas as pd     # Deal with TSV files (design)
import sys              # System related operations

# Snakemake-Wrappers version
swv = "0.35.1"
# github prefix
git = "https://bitbucket.org/tdayris/snakemake-wrappers/raw"

# Loading configuration
configfile: "config.yaml"
validate(config, schema="../schemas/config.schema.yaml")

# Loading deisgn file
design = pd.read_csv(
    config["design"],
    sep="\t",
    header=0,
    index_col=None,
    dtype=str
)
design.set_index(design["Sample_id"])
validate(design, schema="../schemas/design.schema.yaml")

report: "../report/general.rst"


def fq_link() -> Dict[str, str]:
    """
    This function takes the "samples" described in config and returns
    a dictionnary with:
    sample file name : sample path
    """
    # Will cause KeyError on single stranded RNA-Seq analysis
    # Better ask forgiveness than permission !
    try:
        # Paired-ended case
        fq_list = chain(design["Upstream_file"], design["Downstream_file"])
    except KeyError:
        # Single ended case
        fq_list = design["Upstream_file"]
    finally:
        return {
            op.basename(fq): op.realpath(fq)
            for fq in fq_list
        }


def fq_root() -> Dict[str, str]:
    """
    This function takes the fastq file list and returns the root
    name corresponding to a fastq file
    sample name: sample link path
    """
    # For now, bz2 compression is not taken into account.
    possible_ext = ("fq", "fastq", "fq.gz", "fastq.gz")

    # Will cause KeyError on single stranded RNA-Seq analysis
    # Better ask forgiveness than permission !
    try:
        # Paired-ended case
        fq_list = chain(design["Upstream_file"], design["Downstream_file"])
    except KeyError:
        # Single ended case
        fq_list = design["Upstream_file"]

    # Build final result
    result = {}
    for fq in fq_list:
        # I always love writing these crazy for-break-else!
        for ext in possible_ext:
            if fq.endswith(ext):
                # Extension removal
                base = op.basename(fq)[:-(len(ext) + 1)]
                result[base] = f"raw_data/{op.basename(fq)}"
                break
        else:
            raise ValueError(f"Could not remove ext: {fq}")

    return result


def ref_link() -> Dict[str, str]:
    """
    This function takes the "ref" described in config and returns
    a dictionnary with:
    ref file name : ref path
    """
    # If not GTF is provided, error will be raised.

    fasta = config["ref"]["fasta"]
    fasta_name = op.basename(fasta)
    fasta_stem = op.splitext(fasta)[0]
    references = {
        fasta_name: op.realpath(fasta),
        f"{op.basename(fasta_stem)}.dict": f"{op.realpath(fasta_stem)}.dict",
        f"{fasta_name}.fai": f"{op.realpath(fasta)}.fai"
    }

    for f in config["ref"]["known"]:
        references[op.basename(f)] = op.realpath(f)
        references[f"{op.basename(f)}.tbi"] = f"{op.realpath(f)}.tbi"

    return references


def fq_pairs() -> Dict[str, str]:
    """
    This function returns a sample ID and
    the corresponding fastq files.
    """
    # Will cause KeyError on single stranded RNA-Seq analysis
    # Better ask forgiveness than permission !
    try:
        # Paired end case
        iterator = zip(
            design["Sample_id"],
            design["Upstream_file"],
            design["Downstream_file"]
        )
        return {
            name: [
                f"raw_data/{op.basename(fq1)}",
                f"raw_data/{op.basename(fq2)}"
            ]
            for name, fq1, fq2 in iterator
        }
    except KeyError:
        # Single end case
        iterator = zip(
            design["Sample_id"],
            design["Upstream_file"]
        )
        return {
            name: [f"raw_data/{op.basename(fq1)}"]
            for name, fq1 in iterator
        }


def refs_pack() -> Dict[str, str]:
    """
    Return a dictionnary with references
    """
    return {
        "fasta": f"genome/{op.basename(config['ref']['fasta'])}",
        "faidx": f"genome/{op.basename(config['ref']['fasta'])}.fai",
        "fadict": f"genome/{op.splitext(op.basename(config['ref']['fasta']))[0]}.dict",
        "known_vcf": [
            f"genome/{op.basename(f)}" for f in config["ref"]["known"]
        ],
        "known_index": [
            f"genome/{op.basename(f)}.tbi" for f in config["ref"]["known"]
        ]
    }


def fq_pairs_w(wildcards) -> Dict[str, str]:
    """
    Dynamic wildcards call for snakemake.
    """
    return {"reads": fq_pairs_dict[wildcards.sample]}


def sample_id() -> List[str]:
    """
    Return the list of samples identifiers
    """
    return design["Sample_id"].tolist()


def get_gatk_args(wildcards) -> str:
    """
    Return enhanced GATK arguments
    """
    if "--TMP_DIR" not in config['params']['gatk_bqsr_extra']:
        return (
            f"{config['params']['gatk_bqsr_extra']} "
            f"--TMP_DIR TMP_BQSR_{wildcards.sample}"
        )
    return config['params']['gatk_bqsr_extra']


def get_java_args(wildcards, resources) -> str:
    """
    Return java args for GATK
    """
    makedirs("tmp")
    return (
        f"-Djava.io.tmpdir=tmp/JAVA_TMP_{wildcards.sample} "
        f"-Xmx{resources.mem_mb}m"
    )


def get_picard_dedup_stats(sample) -> str:
    """
    Return the Picard MarkDuplicates parameters including
    statistics
    """
    if "METRICS_FILE" not in config["params"]["picard_dedup_extra"]:
        return (
            f"{config['params']['picard_dedup_extra']} "
            f"METRICS_FILE picard/stats/dedup/{sample}.metrics.txt"
        )
    return config["params"]["picard_dedup_extra"]


def get_targets(no_multiqc=False) -> Dict[str, Any]:
    """
    This function returns the targets of Snakemake
    following the requests from the user.
    """
    targets = {}
    if config["workflow"]["fastqc"] is True:
        targets["fastqc"] = expand(
            "qc/fastqc/{samples}_fastqc.{ext}",
            samples=fq_root_dict.keys(),
            ext=["html", "zip"]
        )
    if config["workflow"]["gatk"] is True:
        targets["gatk"] = expand(
            "picard/deduplicated/{sample}.bam",
            sample=sample_id_list
        )
        targets["picard_dedup"] = expand(
            "picard/stats/duplicates/{sample}.metrics.txt",
            sample=sample_id_list
        )
        if "Downstream_file" in design.columns.tolist():
            targets["picard_isize"] = expand(
                "picard/stats/size/{sample}.isize.txt",
                sample=sample_id_list
            )
        targets["picard_summary"] = expand(
            "picard/stats/summary/{sample}_summary.txt",
            sample=sample_id_list
        )
    if config["workflow"]["multiqc"] is True and no_multiqc is False:
        targets["multiqc"] = "qc/multiqc_report.html"

    return targets


# We will use these functions multiple times. On large input datasets,
# pre-computing all of these makes Snakemake faster.
fq_link_dict = fq_link()
fq_root_dict = fq_root()
ref_link_dict = ref_link()
fq_pairs_dict = fq_pairs()
refs_pack_dict = refs_pack()
sample_id_list = sample_id()
targets_dict = get_targets()
