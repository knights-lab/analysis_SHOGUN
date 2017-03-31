"""
Analysis of the SHOGUN.
"""

__author__ = "Benjamin Hillmann"
__license__ = "MIT"

from snakemake.utils import min_version
min_version("3.11.2")

import os

## Include the config
configfile: "config.yaml"

contexts = ["test"]

if config["benchmarks"] == "True":
    results = expand("results/{context}/indices_time_and_memory_table.txt", context=contexts)

rule all:
    input:
        results

#### Indexing of Databases ####
rule index_utree_specific:
    input:
        fasta = config["references"][wildcards.basename] + ".fna",
        tax = config["references"][wildcards.basename] + ".tax"
    output:
        ctr = "{output_path}/{basename}.ctr",
        utree_log = "{output_path}/{basename}.log"
    script:
        """
            utree-build {input.fasta} {input.tax} {wildcards.output_path}/{wildcards.basename}.ubt {threads};
            utree-compress {wildcards.output_path}/{wildcards.basename}.ubt {output.ctr}
            mv {wildcards.output_path}/{wildcards.basename}.ubt.log {output.utree_log}
            rm {wildcards.output_path}/{wildcards.basename}.ubt
        """

#### Benchmarks ####
rule benchmark_build_indices:
    input:
        build_index_utree_specific.input
    output:
        "results/{context}/indices_time_and_memory_table.txt"
    script:
        "script/benchmark_build_indices.py"

rule benchmark_alignment:

#### Tables ####
rule generate_indices_time_and_memory_table:
    input:
        # UTREE
        expand("{ref}/{basename}.{k}.time_mem.log", ref = REFS, basename = REF_BASENAMES, k = range(3))
    output:
        expand("results/{context}/{name}_table.txt", output_path=result_path, name="indices_time_and_memory")
    shell:
        "{script_path}/generate_indices_time_and_memory_table.py {input}.time_mem.log >> {output}"

#### Plots ####
