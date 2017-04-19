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
    results = expand("results/{context}/benchmark_index.miniGWG.100.{k}.log", context=contexts, k=config["benchmark_replicates"])
    print(results)

rule all:
    input:
        results

### Indexing of Databases
rule benchmark_index_utree:
    input:
        fasta = config["reference"]["test"] + "/{basename}.fna",
        tax = config["reference"]["test"] + "/{basename}.tax"
    output:
        ctr = "{output_path}/{basename}.ctr",
        utree_log = "{output_path}/{basename}.log",
        benchmark = expand("{output_path}/benchmark_index.{basename}.{benchmark_replicate}.log", benchmark_replicate=range(config["benchmark_replicates"]))
    run:
        for i in range(config["benchmark_replicates"]):
            shell("/usr/bin/time -v sh -c 'utree-build {input.fasta} {input.tax} {wildcards.output_path}/{wildcards.basename}.ubt {threads}; utree-compress {wildcards.output_path}/{wildcards.basename}.ubt {output.ctr}' >> {output.benchmark} 2>&1; ")
            shell("mv {wildcards.output_path}/{wildcards.basename}.ubt.log {output.utree_log}")
            shell("rm {wildcards.output_path}/{wildcards.basename}.ubt")

### Benchmarks

### Tables

#### Plots ####
