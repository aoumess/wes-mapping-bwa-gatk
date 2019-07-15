#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script is here to help you prepare the cofig file
for the pipeline wes-mapping-bwa-gatk
"""

import yaml

from argparse import ArgumentParser
from pathlib import Path

if __name__ == '__main__':
    main_parser = ArgumentParser(
        description="Build your config file with this script",
        epilog="This script does not perform any magic. Check the config file."
    )

    main_parser.add_argument(
        "fasta",
        help="Path to the genome sequence file file",
        type=str
    )

    main_parser.add_argument(
        "known_vcf",
        help="Space separated list of paths to known vcf files",
        type=str,
        nargs="+"
    )

    main_parser.add_argument(
        "-d", "--design",
        help="Path to the design file (default: %(default)s)",
        type=str,
        default="design.tsv"
    )

    main_parser.add_argument(
        "-w", "--workdir",
        help="Path to raw data directory (default: %(default)s)",
        type=str,
        default="."
    )

    main_parser.add_argument(
        "-t", "--threads",
        help="Maximum number of threads used (default: %(default)s)",
        type=int,
        default=1
    )

    main_parser.add_argument(
        "-s", "--singularity",
        help="Name of the docker/singularity image (default: %(default)s)",
        type=str,
        default="docker://continuumio/miniconda3:4.4.10"
    )

    main_parser.add_argument(
        "--cold_storage",
        help="Path to cold storage mount points (default: %(default)s)",
        type=str,
        default="None",
        nargs="+"
    )

    main_parser.add_argument(
        "--no_quality_control",
        help="Do not perform any additional quality controls",
        action="store_true"
    )

    main_parser.add_argument(
        "--no_gatk",
        help="Do not perform any GATK recalibration",
        action="store_true"
    )

    main_parser.add_argument(
        "--copy_extra",
        help="Extra parameters for bash copy (default: %(default)s)",
        type=str,
        default="--verbose"
    )

    main_parser.add_argument(
        "--bwa_index_extra",
        help="Extra parameters for bwa index (default: %(default)s)",
        type=str,
        default=""
    )

    main_parser.add_argument(
        "--samtools_fixmate_extra",
        help="Extra parameters for samtools fixmate (default: %(default)s)",
        type=str,
        default="-c -m"
    )

    main_parser.add_argument(
        "--bwa_map_extra",
        help="Extra parameters for bwa mem (default: %(default)s)",
        type=str,
        default="-T 20 -M"
    )

    main_parser.add_argument(
        "--picard_sort_sam_extra",
        help="Extra parameters for picard sort sam (default: %(default)s)",
        type=str,
        default=""
    )

    main_parser.add_argument(
        "--picard_group_extra",
        help="Extra parameters for picard read groups (default: %(default)s)",
        type=str,
        default="RGLB=standard RGPL=novaseq RGPU={sample} RGSM={sample}"
    )

    main_parser.add_argument(
        "--picard_dedup_extra",
        help="Extra parameters for Picard deduplicate (default: %(default)s)",
        type=str,
        default="REMOVE_DUPLICATES=true"
    )

    main_parser.add_argument(
        "--picard_isize_extra",
        help="Extra parameters for Picard insert "
             "size stats (default: %(default)s)",
        type=str,
        default="METRIC_ACCUMULATION_LEVEL=SAMPLE"
    )

    main_parser.add_argument(
        "--gatk_bqsr_extra",
        help="Extra parameters for GATK BQSR (default: %(default)s)",
        type=str,
        default=""
    )

    main_parser.add_argument(
        "--picard_summary_extra",
        help="Extra parameters for Picard summary"
             "(default: %(default)s)",
        type=str,
        default=""
    )

    args = main_parser.parse_args()

    config_params = {
        "design": args.design,
        "workdir": args.workdir,
        "threads": args.threads,
        "singularity_docker_image": args.singularity,
        "cold_storage": args.cold_storage,
        "ref": {
            "fasta": args.fasta,
            "known": args.known_vcf
        },
        "workflow": {
            "fastqc": not args.no_quality_control,
            "multiqc": not args.no_quality_control,
            "picard": not (args.no_quality_control and args.no_gatk),
            "gatk": not args.no_gatk
        },
        "params": {
            "copy_extra": args.copy_extra,
            "bwa_index_extra": args.bwa_index_extra,
            "bwa_map_extra": args.bwa_map_extra,
            "bwa_indpicard_sort_sam_extraex_extra": args.picard_sort_sam_extra,
            "picard_group_extra": args.picard_group_extra,
            "picard_dedup_extra": args.picard_dedup_extra,
            "picard_isize_extra": args.picard_isize_extra,
            "gatk_bqsr_extra": args.gatk_bqsr_extra,
            "picard_summary_extra": args.picard_summary_extra,
            "picard_sort_sam_extra": args.picard_sort_sam_extra,
            "samtools_fixmate_extra": args.samtools_fixmate_extra
        }
    }

    output_path = Path(args.workdir) / "config.yaml"
    with output_path.open("w") as config_yaml:
        config_yaml.write(yaml.dump(config_params, default_flow_style=False))
