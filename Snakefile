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
results.extend(expand("results/indices/kraken_{context}", context=config['contexts']))
results.extend(expand("results/indices/centrifuge_{context}", context=config['contexts']))

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
        "utree-build {input.fasta} {input.tax} {params.ubt} {threads}; "
        "utree-compress {params.ubt} {output.ctr}; "
        "mv {params.ubt}.log {output.log}; "
        "rm {params.ubt}"

rule krakenify_gmg:
    input:
        unpack(get_references),
        mapping = "data/references/a2t.rs81.txt"
    output:
        "results/indices/kraken_{basename}.fna"
    script:
        "scripts/krakenify_gmg.py"

rule index_kraken:
    input:
        "results/indices/kraken_{basename}.fna"
    params:

    output:
        "results/indices/kraken_{basename}"
    threads: 12
    shell:
        "kraken-build --download-taxonomy --db {output}; "
        "kraken-build --add-to-library {input} --db {output} --threads {threads}; "
        "kraken-build --build --db {output}; "
        "kraken-build --clean --db {output}"

rule index_centrifuge_taxonomy:
	params:
		path="results/indicies/centrifuge_taxonomy"
	output:
		nodes="results/indices/centrifuge_taxonomy/nodes.dmp",
		names="results/indicies/centrifuge_taxonomy/names.dmp"
	shell:
		"centrifuge-download -o taxonomy {params.path}"

rule centrifugify_gmg:
    input:
        unpack(get_references),
        mapping = "data/references/a2t.rs81.txt"
    output:
        "results/indices/centrifuge_{basename}.map"
    script:
        "scripts/centrifugify_gmg.py"

rule index_centrifuge:
	input:
		conversion_table="results/indices/centrifuge_{basename}.map",
	    taxonomy_tree="results/indices/centrifuge_taxonomy/nodes.dmp",
		name_table="results/indicies/centrifuge_taxonomy/names.dmp",
		unpack(get_references),
	output:
    	"results/indices/centrifuge_{basename}"
    benchmark:
    	"results/benchmarks/index_centrifuge_{basename}.log"
	threads: 12
	shell:
		"centrifuge-build --conversion-table {input.conversion_table} --taxonomy-tree {input.taxonomy_tree} --name-table {input.name_table} {input.fasta} {output}"


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
        shell("rm {params.ubt}.log")
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
