#!/usr/bin/env python
"""
Annotates a file

Example usage:
"""

import argparse
import csv
from collections import defaultdict
from dojo.taxonomy import NCBITree
import sys

from ninja_utils.parsers import FASTA


def make_arg_parser():
    parser = argparse.ArgumentParser(description='')
    # genomes_path = os.path.join('..', 'results', '170214-simulation', 'genomes')
    parser.add_argument('-r', '--refseq_mapper', type=str, required=True)
    parser.add_argument('-f', '--fasta', type=str, required=True)
    # os.path.join('..', 'results', 'genome_lengths.json'), 'w'
    # parser.add_argument('-o', '--output', type=str, required=True)
    return parser


def main():
    parser = make_arg_parser()
    args = parser.parse_args()

    header_to_taxid = {}
    with open(args.refseq_mapper) as inf:
        next(inf)
        for line in inf:
            line = line.split('\t')
            header_to_taxid[line[0].split('.')[0]] = line[1]

    with open(args.fasta) as inf:
        fasta = FASTA(inf)
        for header, seq in fasta.read():
            refseq_id = header.split(' ')[0]
            if refseq_id in header_to_taxid:
                taxid = header_to_taxid[refseq_id]
                print(">taxid|%s|%s" % (taxid, header))
                print(seq)

if __name__ == '__main__':
    main()
