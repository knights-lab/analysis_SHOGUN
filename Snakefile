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

results = []
if config["settings"]["benchmarks"]:
    results.extend(expand("results/tables/benchmark_{context}_index.txt", context=config['contexts']))

results.extend(expand("results/indices/{context}.ctr", context=config['contexts']))

rule all:
    input:
        results

rule clean:
    shell:
        "rm -rf results"

def get_references(wildcards):
    fasta = expand("{path}/{basename}.fna", path=config["reference"][wildcards.basename], basename=wildcards.basename)
    tax = expand("{path}/{basename}.tax", path=config["reference"][wildcards.basename], basename=wildcards.basename)
    return dict(zip(("fasta", "tax"), (fasta, tax)))

### Index Creation
rule index_utree:
    input:
        unpack(get_references),
    params:
        ubt = "results/indices/{basename}.ubt"
    output:
        ctr = "results/indices/{basename}.ctr",
        log = "results/indices/{basename}.log",
    shell:
        "utree-build {input.fasta} {input.tax} {params.ubt} {threads}"
        "utree-compress {params.ubt} {output.ctr}"
        "mv {params.ubt}.ubt.log {output.log}"
        "rm {params.ubt}"

### Benchmarks

### Indexing of Databases
rule benchmark_index_utree:
    input:
        unpack(get_references),
    params:
        ctr = "results/benchmarks/{basename}_{k}.ctr",
        ubt = "results/benchmarks/{basename}.ubt"
    output:
        benchmark = "results/benchmarks/index_utree_{basename}_{k}.log",
    threads: 12
    run:
        shell("/usr/bin/time -v sh -c 'utree-build {input.fasta} {input.tax} {params.ubt} {threads}; utree-compress {params.ubt} {params.ctr}' >> {output.benchmark} 2>&1")
        shell("rm {params.ubt}.ubt.log")
        shell("rm {params.ubt}")
        shell("rm {params.ctr}")

rule combine_benchmarks:
    input:
        lambda wildcards: expand("results/benchmarks/index_{tool}_{basename}_{k}.log", tool=wildcards.tool, k=range(config["benchmark_replicates"]), basename=wildcards.basename)
    output:
        "results/benchmarks/combined_index_{tool}_{basename}.log"
    shell:
        "cat {input} > {output}"

### Tables
rule table_index_benchmarks:
    input:
        lambda wildcards: expand("results/benchmarks/combined_index_{tool}_{basename}.log", tool=config["tools"], basename=wildcards.context)
    output:
        "results/tables/benchmark_{context}_index.txt"
    script:
        "scripts/table_index_benchmarks.py"


#### Plots ####
