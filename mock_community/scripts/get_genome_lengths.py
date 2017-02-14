#!/usr/bin/env python
"""
Writes a JSON dict that has:

DICT[assembly_accession] -> (relative_path, genome_length_bp)
Example usage:
python scripts/get_genome_lengths.py" -p results/170214-simulation/genomes -o results/170214-genome_lengths
"""

import os
from ninja_utils.parsers import FASTA
import json
import argparse


def make_arg_parser():
    parser = argparse.ArgumentParser(description='')
    # genomes_path = os.path.join('..', 'results', '170214-simulation', 'genomes')
    parser.add_argument('-p', '--genomes_path', type=str, required=True)
    # os.path.join('..', 'results', 'genome_lengths.json'), 'w'
    parser.add_argument('-o', '--outfile_dir', type=str, required=True)
    return parser


def main():
    parser = make_arg_parser()
    args = parser.parse_args()

    if not os.path.exists(args.outfile_dir):
        os.makedirs(args.outfile_dir)

    genomes_path = args.genomes_path
    lengths_dict = {}
    for filename in os.listdir(genomes_path):
        if filename.endswith('.fna'):
            with open(os.path.join(genomes_path, filename)) as inf:
                inf_fasta = FASTA(inf)
                for header, seq in inf_fasta.read():
                    lengths_dict['_'.join(filename.split('_')[:2])] = (os.path.abspath(os.path.join(genomes_path, filename)), len(seq))

    with open(os.path.join(args.outfile_dir, 'genome_lengths.json'), 'w') as outf:
        outf.write(json.dumps(lengths_dict))

if __name__ == '__main__':
    main()
