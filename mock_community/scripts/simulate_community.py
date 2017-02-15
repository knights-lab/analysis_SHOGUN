#!/usr/bin/env python
"""
Simulate a DWGSIM Illumina Hi-Seq run from the output of create_prevalence communities and get_genome_lengths

Run this script last

Example run:
scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\gut_0.csv -o results\170214-gut_example
"""

import os
import json
import pandas as pd
import numpy as np
from dojo.taxonomy import NCBITree
from ninja_utils.utils import run_command
import argparse


def make_arg_parser():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-g', '--genome_lengths', type=str, required=True)
    parser.add_argument('-a', '--assembly_summary_file', type=str, required=True)
    parser.add_argument('-o', '--outfile_dir', type=str, required=True)
    parser.add_argument('-n', '--num_sequences', type=int, default=10000000)
    return parser


def create_dwgsim_illumina_hiseq(file_path, fq_outfile, count, seed=99):
    return ['dwgsim', '-E', '0.001', '-e', '0.001', '-r', '0.001', '-q', 'f', '-c', '0', '-1', '100',
            '-2', '100', '-N', str(count), '-y', '0.0', '-z', str(seed), file_path, fq_outfile]


def main():
    parser = make_arg_parser()
    args = parser.parse_args()

    if not os.path.exists(args.outfile_dir):
        os.makedirs(args.outfile_dir)

    # DICT[assembly_accession] -> (relative_path, genome_length_bp)
    with open(args.genome_lengths) as json_inf:
        genomes_dict = json.load(json_inf)

    inf_practice = args.assembly_summary_file

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
        if row['assembly_accession'] in genomes_dict:
            file_path, genome_length = genomes_dict[row['assembly_accession']]
            file_paths.append(file_path)
            counts.append(genome_length)
            assembly_accessions.append(row['assembly_accession'])
            taxids.append(row['taxid'])
            species_taxids.append(row['species_taxid_x'])
            green_genes_taxonomies.append(tree.green_genes_lineage(row['taxid'], depth=8, depth_force=True))

    # validate the count arrays
    counts = np.array(counts)
    counts = counts / counts.sum()
    counts = counts * args.num_sequences
    # convert counts to int
    counts = counts.astype(np.int)

    df = pd.DataFrame(np.array([counts, assembly_accessions, taxids, species_taxids, green_genes_taxonomies]).T,
                      columns=['count', 'assembly_accession', 'taxid', 'species_taxid', 'green_gene_taxonomy'])
    df.to_csv(os.path.join(args.outfile_dir, 'name.csv'))

    for file_path, count in zip(file_paths, counts):
        #dwgsim stuff here
        assembly_accession = os.path.basename(file_path)[:-4]
        assembly_accession = '_'.join(assembly_accession.split('_')[:2])
        taxid = df[df['assembly_accession'] == assembly_accession]['taxid']
        run_command(create_dwgsim_illumina_hiseq(file_path, os.path.join(args.outfile_dir, assembly_accession + '.taxid.%d.simulated' % taxid), count))


if __name__ == '__main__':
    main()
