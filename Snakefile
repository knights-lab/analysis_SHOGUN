"""
Analysis for the SHOGUN paper
"""

__author__ = "Benjamin Hillmann"
__license__ = "MIT"

from snakemake.utils import min_version

min_version("3.11.2")

import os

## Include the config
configfile: "config.yaml"

contexts = ["test"]

if config["settings"]["debug"]:
    import ipdb

if config["settings"]["benchmarks"]:    
    ipdb.set_trace()
    results = expand("results/{context}/", context=contexts)

rule all:
    input:
        results

### Indexing of Databases
rule benchmark_index_utree:
    input:
        fasta = config["reference"][wildcards.basename] + ".fna",
        tax = config["reference"][wildcards.basename] + ".tax"
    output:
        ctr = "{output_path}/{basename}.ctr",
        utree_log = "{output_path}/{basename}.log",
        benchmark = expand("{output_path}/benchmark_index.{basename}.{k}.log", k=range(3))
    script:
        """
            for value in {1..3}
            do
                /usr/bin/time -v sh -c 'utree-build {input.fasta} {input.tax} {wildcards.output_path}/{wildcards.basename}.ubt {threads};
                utree-compress {wildcards.output_path}/{wildcards.basename}.ubt {output.ctr}' >> {output.benchmark[value]}
                mv {wildcards.output_path}/{wildcards.basename}.ubt.log {output.utree_log}
                rm {wildcards.output_path}/{wildcards.basename}.ubt
            done
        """

### Benchmarks
rule benchmark_build_indices:
    input:
        build_index_utree_specific.input
    output:
        "results/{context}/indices_time_and_memory_table.txt"
    script:
        "script/benchmark_build_indices.py"

rule benchmark_alignment:

### Tables
rule generate_indices_time_and_memory_table:
    input:
        # UTREE
        expand("{ref}/{basename}.{k}.time_mem.log", ref = REFS, basename = REF_BASENAMES, k = range(3))
    output:
        expand("results/{context}/{name}_table.txt", output_path=result_path, name="indices_time_and_memory")
    shell:
        "{script_path}/generate_indices_time_and_memory_table.sh {input}.time_mem.log >> {output}"

#### Plots ####
