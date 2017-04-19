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
    results = expand("results/miniGMG.ctr")

rule all:
    input:
        results

### Indexing of Databases
rule benchmark_index_utree:
    input:
        fasta = config["reference"][wildcards.context] + ".fna",
        tax = config["reference"][wildcards.context] + ".tax"
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

### Tables

#### Plots ####
