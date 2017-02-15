#!/usr/bin/env python
"""
This script will use the HMP Prevlance CSV to grab the most prevalent bacteria for stool, skin and saliva samples.

Run this script first.

Example run:
python scripts/create_prevalence_communities.py -p data\HMP_taxon_prevalence.csv -a data\assembly_summary.txt -o results\170214-genus
"""

import pandas as pd
import os
from dojo.taxonomy import NCBITree
import urllib.request
from ninja_utils.utils import stream_gzip_decompress

import numpy as np
import argparse


def make_arg_parser():
    parser = argparse.ArgumentParser(description='')
    # os.path.join('..', 'data', 'HMP_taxon_prevalence.csv')
    parser.add_argument('-p', '--prevalence_csv', type=str, required=True)
    # refseqv80 summary file
    # os.path.join('..', 'data', 'assembly_summary.txt')
    parser.add_argument('-a', '--assembly_summary', type=str, required=True)
    # os.path.join('..', 'data', 'ncbi_tid_HMP_taxon_prevalence.csv')
    parser.add_argument('-o', '--outfile_dir', type=str, required=True)
    parser.add_argument('-f', '--ftp', type=bool, default=True)
    return parser


def main():
    parser = make_arg_parser()
    args = parser.parse_args()

    # Check and make the outfile dir
    if not os.path.exists(args.outfile_dir):
        os.makedirs(args.outfile_dir)

    if not os.path.exists(os.path.join(args.outfile_dir, 'genomes')):
        os.makedirs(os.path.join(args.outfile_dir, 'genomes'))

    # Grab the prevalence df
    prevalence_df = pd.read_csv(args.prevalence_csv)

    # Grab the list of taxonomy names
    tree = NCBITree()

    x = [tree.get_taxon_id_lineage_with_name(species) for species in prevalence_df['Species']]
    species_ncbi_tids = [None]*len(x)
    genus_ncbi_tids = [None]*len(x)

    for i, (ncbi_tid, name) in enumerate(zip(x, prevalence_df['Species'])):
        if not ncbi_tid:
            genus_ncbi_tids[i] = next(tree.get_taxon_id_lineage_with_name(name.split(' ')[0]))
        else:
            species_ncbi_tids[i] = next(x[i])
            genus_ncbi_tids[i] = next(x[i])

    prevalence_df['species_taxid'] = species_ncbi_tids
    prevalence_df['genus_taxid'] = genus_ncbi_tids

    prevalence_df.to_csv(os.path.join(args.outfile_dir, 'HMP_taxid_prevalence.csv'))

    #Index(['assembly_accession', 'bioproject', 'biosample', 'wgs_master',
    #      'refseq_category', 'taxid', 'species_taxid', 'organism_name',
    #      'infraspecific_name', 'isolate', 'version_status', 'assembly_level',
    #      'release_type', 'genome_rep', 'seq_rel_date', 'asm_name', 'submitter',
    #      'gbrs_paired_asm', 'paired_asm_comp', 'ftp_path',
    #      'excluded_from_refseq'],
    #      dtype='object')
    assembly_summary_df = pd.read_csv(args.assembly_summary, sep='\t')
    assembly_summary_df = assembly_summary_df[assembly_summary_df['refseq_category'] != 'na']

    genus_taxids = [None]*assembly_summary_df.shape[0]
    for i, taxid in enumerate(assembly_summary_df['taxid']):
        genus_taxid = tree.get_lineage(taxid, ranks=['genus'])
        if len(genus_taxid) > 0:
            genus_taxids[i] = genus_taxid[0][1]

    assembly_summary_df['genus_taxid'] = genus_taxids

    # isnull 64
    # ~isnull 301
    species_df = prevalence_df[~prevalence_df['species_taxid'].isnull()]

    # df_merged = pd.merge(assembly_summary_df, species_df, on=['species_taxid'], how='inner')
    prevalence_group = prevalence_df.groupby(['genus_taxid']).mean()
    prevalence_group['genus_taxid'] = prevalence_group.index
    df_merged = pd.merge(assembly_summary_df, prevalence_group, on=['genus_taxid'], how='inner')
    df_merged.to_csv(os.path.join(args.outfile_dir, 'HMP_taxid_prevalence_merged.csv'))

    ftp_links = set()
    # Species only no genus
    # Use the uniform distribution
    for type in ['Gut', 'Oral', 'Skin']:
        for i in range(5):
            dist = np.random.uniform(0, 1, df_merged.shape[0])
            mask = df_merged['%s prevalence' % type] > dist
            print('%s_%d.csv' % (type, i))
            print('Number of Unique Strains: %d' % (np.sum(mask)))
            df_merged[mask].to_csv(os.path.join(args.outfile_dir, '%s_%d.csv' % (type, i)))
            print('Number of Unique Species: %d' % (np.unique(df_merged[mask]['species_taxid']).shape[0]))
            # print('Number of Unique Species: %d' % (np.unique(df_merged[mask]['species_taxid']).shape[0]))
            [ftp_links.add(i + '/%s_genomic.fna.gz' % (i.split('/')[-1])) for i in df_merged['ftp_path']]

    with open(os.path.join(args.outfile_dir, 'ftp_links.txt'), 'w') as outf:
        for i in ftp_links:
            outf.write('%s\n' % i)

    if args.ftp:
        # Download genomes and decompress
        for ftp_link in ftp_links:
            outfile_path = os.path.join(args.outfile_dir, 'genomes', ftp_link.split('/')[-1][:-3])
            if not os.path.isfile(outfile_path):
                with open(outfile_path, 'wb') as outf:
                    with urllib.request.urlopen(ftp_link) as stream:
                        for rv in stream_gzip_decompress(stream):
                            outf.write(rv)

if __name__ == '__main__':
    main()
