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
    results = "results/index/combined_benchmark_index.miniGWG.100.log"

rule all:
    input:
        results

### Indexing of Databases
rule benchmark_index_utree:
    input:
        fasta = config["reference"]["test"] + "/{basename}.fna",
        tax = config["reference"]["test"] + "/{basename}.tax",
    params:
        ctr = "{output_path}/{basename}.{k}.ctr",
    output:
        benchmark = "{output_path}/benchmark_index.{basename}.{k}.log",
    run:
        shell("/usr/bin/time -v sh -c 'utree-build {input.fasta} {input.tax} {wildcards.output_path}/{wildcards.basename}.ubt {threads}; utree-compress {wildcards.output_path}/{wildcards.basename}.ubt {params.ctr}' >> {output.benchmark} 2>&1")
        shell("rm {wildcards.output_path}/{wildcards.basename}.ubt.log")
        shell("rm {wildcards.output_path}/{wildcards.basename}.ubt")
        shell("rm {params.ctr}")

rule combine_benchmarks:
    input:
        expand("results/{context}/{basename}.{k}.log", context=contexts, k=range(config["benchmark_replicates"]))
    output:
        "{output_path}/combined_benchmark_index.{basename}.log"
    shell:
        "cat {input} > {output}"

### Benchmarks

### Tables

#### Plots ####
