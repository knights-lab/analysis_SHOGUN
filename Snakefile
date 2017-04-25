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
results.extend(expand("results/indices/centrifuge_{context}/centrifuge_{context}.{k}.cf", context=config['contexts'], k=[1,2,3]))

UDS_RUNS = ['160729_K00180_0226_AH7WCCBBXX', '160729_K00180_0227_BHCT3LBBXX']
UDS_SAMPLES = []
for run in UDS_RUNS:
    temp, = glob_wildcards("data/hiseq4000/%s/{sample_name}.fastq.gz" % run)
    UDS_SAMPLES.extend(temp)

results.extend(expand("results/uds/{uds_run}/{sample_name}_{context}.b6", context=['miniGWG_darth'], uds_run=UDS_RUNS, samples_name=UDS_SAMPLES))

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

def get_embalmer_references(wildcards):
    edx = expand("{path}/{basename}.edx", path=config["reference"][wildcards.basename], basename=wildcards.basename)
    acx = expand("{path}/{basename}.acx", path=config["reference"][wildcards.basename], basename=wildcards.basename)
    tax = expand("{path}/{basename}.tax", path=config["reference"][wildcards.basename], basename=wildcards.basename)
    return dict(zip(("edx", "acx", "tax"), (edx, acx, tax)))


### Index Creation
rule index_utree:
    input:
        unpack(get_references),
    params:
        ubt = "results/indices/{basename}.ubt"
    output:
        ctr = "results/indices/{basename}.ctr",
        log = "results/indices/{basename}.log",
    benchmark:
        "results/benchmarks/index_utree_{basename}.log"
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
    benchmark:
        "results/benchmarks/index_kraken_{basename}.log"
    shell:
        "kraken-build --download-taxonomy --db {output}; "
        "kraken-build --add-to-library {input} --db {output} --threads {threads}; "
        "kraken-build --build --db {output}; "
        "kraken-build --clean --db {output}"

rule index_centrifuge_taxonomy:
    params:
        path="results/indices/centrifuge_taxonomy"
    output:
        nodes="results/indices/centrifuge_taxonomy/nodes.dmp",
        names="results/indices/centrifuge_taxonomy/names.dmp"
    shell:
        "centrifuge-download -o {params.path} taxonomy"

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
        unpack(get_references),
        conversion_table="results/indices/centrifuge_{basename}.map",
        taxonomy_tree="results/indices/centrifuge_taxonomy/nodes.dmp",
        name_table="results/indices/centrifuge_taxonomy/names.dmp",
    params:
        path = "results/indices/centrifuge_{basename}/centrifuge_{basename}"
    output:
        "results/indices/centrifuge_{basename}/centrifuge_{basename}.1.cf",
        "results/indices/centrifuge_{basename}/centrifuge_{basename}.2.cf",
        "results/indices/centrifuge_{basename}/centrifuge_{basename}.3.cf",
    benchmark:
        "results/benchmarks/index_centrifuge_{basename}.log"
    threads: 12
    shell:
        "centrifuge-build -p {threads} --conversion-table {input.conversion_table} --taxonomy-tree {input.taxonomy_tree} --name-table {input.name_table} {input.fasta} {params.path}"


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

### Ultra-Deep Sequencing
rule extract_uds:
    input:
        "data/hiseq4000/{uds_run}/{sample_name}.fastq.gz"
    output:
        temp("results/uds/temp/{uds_run}/{sample_name}/{sample_name}.fastq")
    shell:
        "7z x {input} -o {output}"

rule quality_control_uds:
    input:
        "results/uds/temp/{uds_run}/{sample_name}/{sample_name}.fastq"
    params:
        "results/uds/temp/{uds_run}/{sample_name}"
    output:
        temp("results/uds/temp/{uds_run}/shi7/{sample_name}.fastq")
    shell:
        "shi7.py -SE --combine_fasta False -i {params} -o {output} --adaptor Nextera -trim_q 32 -filter_q 36 --strip_underscore"

rule emb_place_on_ramdisk:
    input:
        unpack(get_embalmer_references)
    output:
        temp("/dev/shm/{context}.edx"),
        temp("/dev/shm/{context}.adx"),
        temp("/dev/shm/{context}.tax"),

rule align_uds:
    input:
        queries = "results/uds/temp/{uds_run}/{sample_name}/{shi7_name}.fna",
        edx = "/dev/shm/{context}.edx",
        acx = "/dev/shm/{context}.adx",
        tax = "/dev/shm/{context}.tax",
    benchmark:
        "results/benchmarks/{sample_name}_emb15_{context}.log"
    output:
        "/dev/shm/uds/{uds_run}/{sample_name}_{context}.b6"
    threads:
        12
    shell:
        "emb15 -r {input.edx} -a {input.adx} -b {input.tax} -q {input.queries} -o {output} -n -m CAPITALIST -bs -fr -i .98 -sa -t {threads}"

rule move_uds:
    input:
        "/dev/shm/uds/{uds_run}/{sample_name}_{context}.b6"
    output:
        "results/uds/{uds_run}/{sample_name}_{context}.b6"
    shell:
        "mv {input} {output}"



### Tables
rule table_index_benchmarks:
    input:
        lambda wildcards: expand("results/benchmarks/combined_index_{tool}_{basename}.log", tool=config["tools"], basename=wildcards.context)
    output:
        "results/tables/benchmark_{context}_index.txt"
    script:
        "scripts/table_index_benchmarks.py"


#### Plots ####
