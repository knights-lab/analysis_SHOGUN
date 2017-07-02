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

strains, _, depths, = glob_wildcards("data/single_strain/{strain1}_analysis/embalmer_results/taxatable_{strain2}{depth}.txt")
results.extend(expand("results/single_strain/{strain}/{strain}{depth}.{level}.txt", strain=strain, depth=depths, level=["strain", "species"]))

#ecoli_b6_files/
#/project/flatiron2/analysis_SHOGUN/data/single_strain/kpneumoniae_analysis/kpneumoniae_b6_files/
#/project/flatiron2/analysis_SHOGUN/data/single_strain/saureus_analysis/saureus_b6_files/

### UDS
UDS_RUNS = ['160729_K00180_0226_AH7WCCBBXX', '160729_K00180_0227_BHCT3LBBXX']

for run in UDS_RUNS:
    path = "data/hiseq4000/%s" % run
    sample_names, = glob_wildcards(path + "/{sample_name}.fastq.gz")
    results.extend(expand("results/uds/{uds_run}.{sample_name}.{context}.b6", context=['miniGWG_darth'], uds_run=run, sample_name=sample_names))

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
    edx = expand("{path}/{basename}.edx", path=config["reference"][wildcards.context], basename=wildcards.context)
    acx = expand("{path}/{basename}.acx", path=config["reference"][wildcards.context], basename=wildcards.context)
    tax = expand("{path}/{basename}.tax", path=config["reference"][wildcards.context], basename=wildcards.context)
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
        temp("/dev/shm/uds/{uds_run}.{sample_name}/{sample_name}.fastq")
    shell:
        "7z x {input} -so > {output}"

rule quality_control_uds:
    input:
        "/dev/shm/uds/{uds_run}.{sample_name}/{sample_name}.fastq"
    params:
        "/dev/shm/uds/{uds_run}.{sample_name}"
    priority: 1
    output:
        temp("/dev/shm/uds/{uds_run}.{sample_name}/combined_seqs.fna"),
        temp("/dev/shm/uds/{uds_run}.{sample_name}/shi7.log"),
    shell:
        "shi7.py -SE --combine_fasta True -i {params} -o {params} --adaptor Nextera -trim_q 32 -filter_q 36 --strip_underscore True -t 24"

rule emb_place_on_ramdisk:
    input:
        unpack(get_embalmer_references)
    priority: 2
    output:
        edx = temp("/dev/shm/uds/{context}.edx"),
        acx = temp("/dev/shm/uds/{context}.acx"),
        tax = temp("/dev/shm/uds/{context}.tax"),
    shell:
        "cp {input.edx} {output.edx}; cp {input.acx} {output.acx}; cp {input.tax} {output.tax}"

rule align_uds:
    input:
        queries = "/dev/shm/uds/{uds_run}.{sample_name}/combined_seqs.fna",
        edx = "/dev/shm/uds/{context}.edx",
        acx = "/dev/shm/uds/{context}.acx",
        tax = "/dev/shm/uds/{context}.tax",
    benchmark: "results/benchmarks/{sample_name}.emb15.{context}.log"
    priority: 3
    output: temp("/dev/shm/uds/{uds_run}.{sample_name}.{context}.b6")
    log: "results/logs/{sample_name}.emb15.{context}.log"
    shell:
        "emb15 -r {input.edx} -a {input.acx} -b {input.tax} -q {input.queries} -o {output} -n -m CAPITALIST -bs -fr -i .98 -sa -t 48 2> {log}"

rule move_uds:
    input:
        "/dev/shm/uds/{uds_run}.{sample_name}.{context}.b6"
    output:
        "results/uds/{uds_run}.{sample_name}.{context}.b6"
    priority: 4
    shell:
        "mv {input} {output}"

### Single Strain
rule single_strain_redistribute_strain:
    input:
        "{path}/taxatable_{strain}.{level}.txt"
    params:
        redis = config["redistribute"],
    output:
        "results/stingle_strain/taxatable_{strain}.strain.txt"
    shell:
        "shogun redistribute --input {input} --output {output} --level  {level} --strain {params}"

### Tables
rule table_index_benchmarks:
    input:
        lambda wildcards: expand("results/benchmarks/combined_index_{tool}_{basename}.log", tool=config["tools"], basename=wildcards.context)
    output:
        "results/tables/benchmark_{context}_index.txt"
    script:
        "scripts/table_index_benchmarks.py"


#### Plots ####
