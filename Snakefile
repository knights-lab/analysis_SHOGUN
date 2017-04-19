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
    results = expand("results/index/combined_benchmark_index.{context}.log", context=config['contexts'])

rule all:
    input:
        results

def get_references(wildcards):
    fasta = expand("{ref_path}/{basename}.fna", ref_path=config["reference"][wildcards.basename], basename=wildcards.basename)
    tax = expand("{ref_path}/{basename}.tax", ref_path=config["reference"][wildcards.basename], basename=wildcards.basename)
    return dict(zip(("fasta", "tax"), (fasta, tax)))

### Indexing of Databases
rule benchmark_index_utree:
    input:
        unpack(get_references)
    params:
        ctr = "{output_path}/{basename}.{k}.ctr",
    output:
        benchmark = "{output_path}/benchmark_index.{basename}.{k}.log",
    threads: 12
    run:
        shell("/usr/bin/time -v sh -c 'utree-build {input.fasta} {input.tax} {wildcards.output_path}/{wildcards.basename}.ubt {threads}; utree-compress {wildcards.output_path}/{wildcards.basename}.ubt {params.ctr}' >> {output.benchmark} 2>&1")
        shell("rm {wildcards.output_path}/{wildcards.basename}.ubt.log")
        shell("rm {wildcards.output_path}/{wildcards.basename}.ubt")
        shell("rm {params.ctr}")

rule combine_benchmarks:
    input:
        lambda wildcards: expand("results/index/benchmark_index.{basename}.{k}.log", k=range(config["benchmark_replicates"]), basename=wildcards.basename)
    output:
        "{output_path}/combined_benchmark_index.{basename}.log"
    shell:
        "cat {input} > {output}"


### Benchmarks

### Tables

#### Plots ####
