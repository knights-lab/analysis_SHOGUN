#!/usr/bin/env python
"""
"""

import os
import json
import pandas as pd
import numpy as np
from dojo.taxonomy import NCBITree
from ninja_utils.utils import run_command


def create_dwgsim_illumina_hiseq(file_path, fq_outfile, count, seed=99):
    return ['dwgsim', '-E', '0.001', '-e', '0.001', '-r', '0.001', '-q', 'f', '-c', '0', '-1', '100', '-2', '100', '-N', str(count), '-y', '0.0', '-z', str(seed), file_path, fq_outfile]

# DICT[assembly_accession] -> (relative_path, genome_length_bp)
with open(os.path.join('..', 'results', 'genome_lengths.json')) as json_inf:
    genomes_dict = json.load(json_inf)

inf_practice = os.path.join('..', 'results', '170213_species', 'Gut_0.csv')

tree = NCBITree()

# ,assembly_accession, species_taxid
inf_df = pd.read_csv(inf_practice)
counts = []
file_paths = []
assembly_accessions = []
taxids = []
species_taxids = []
green_genes_taxonomies = []

for i, row in inf_df.iterrows():
    print(row['assembly_accession'])
    if row['assembly_accession'] in genomes_dict:
        file_path, genome_length = genomes_dict[row['assembly_accession']]
        file_paths.append(file_path)
        counts.append(genome_length)
        assembly_accessions.append(row['assembly_accession'])
        taxids.append(row['taxid'])
        species_taxids.append(row['species_taxid'])
        green_genes_taxonomies.append(tree.green_genes_lineage(row['taxid'], depth=8, depth_force=True))

# validate the count arrays
counts = np.array(counts)
counts = counts / counts.sum()
counts = counts * 40000000

df = pd.DataFrame(np.array([counts, assembly_accessions, taxids, species_taxids, green_genes_taxonomies]).T, columns=['count', 'assembly_accession', 'taxid', 'species_taxid', 'green_gene_taxonomy'])

counts = counts.astype(np.int)

print(df.head())

for file_path, count in zip(file_paths, counts):
    #dwgsim stuff here
    print(file_path)
    run_command(create_dwgsim_illumina_hiseq(file_path, 'outfile.test', count))


