#!/usr/bin/env python
"""
Annotates a file

Example usage:
"""

import os
from ninja_utils.parsers import FASTA
from dojo.taxonomy import NCBITree
from dojo.database import RefSeqDatabase
import json
import argparse
import csv

def make_arg_parser():
    parser = argparse.ArgumentParser(description='')
    # genomes_path = os.path.join('..', 'results', '170214-simulation', 'genomes')
    parser.add_argument('-i', '--input', type=str, required=True)
    # os.path.join('..', 'results', 'genome_lengths.json'), 'w'
    # parser.add_argument('-o', '--output', type=str, required=True)
    return parser


def main():
    parser = make_arg_parser()
    args = parser.parse_args()

    ncbi_tree = NCBITree()
    refseq_db = RefSeqDatabase()

    with open(args.input) as inf:
        csv_inf = csv.reader(inf, delimiter='\t')
        for line in csv_inf:
            refseq_accession_version = line[0]
            taxid = refseq_db.get_ncbi_tid_from_refseq_accession(refseq_accession_version)[0]
            species_taxid = ncbi_tree.get_rank_with_taxon_id(taxid, 'species')[0]
            green_genes_lineage = ncbi_tree.green_genes_lineage(taxid, depth=8)
            outf_line = [line[0], str(species_taxid), str(taxid), green_genes_lineage] + line[1:]
            print('\t'.join(outf_line))

if __name__ == '__main__':
    main()
