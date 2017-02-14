#!/usr/bin/env python
"""
Writes a JSON dict that has:

DICT[assembly_accession] -> (relative_path, genome_length_bp)
"""

import os
from ninja_utils.parsers import FASTA
import json

genomes_path = os.path.join('..', 'results', '170214-simulation', 'genomes')

lengths_dict = {}
for filename in os.listdir(genomes_path):
    if filename.endswith('.fna'):
        with open(os.path.join(genomes_path, filename)) as inf:
            inf_fasta = FASTA(inf)
            for header, seq in inf_fasta.read():
                lengths_dict['_'.join(filename.split('_')[:2])] = (os.path.join(genomes_path, filename), len(seq))

with open(os.path.join('..', 'results', 'genome_lengths.json'), 'w') as outf:
    outf.write(json.dumps(lengths_dict))
