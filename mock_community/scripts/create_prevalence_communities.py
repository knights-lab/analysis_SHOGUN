#!/usr/bin/env python
"""
This script will use the HMP Prevlance CSV to grab the most prevalent bacteria for stool, skin and saliva samples.

It will then simulate a mock community based weighted by genome lengths.
"""

import pandas as pd
import os
from dojo.taxonomy import NCBITree
import numpy as np

# Grab the prevalence df
prevalence_df = pd.read_csv(os.path.join('..', 'data', 'HMP_taxon_prevalence.csv'))

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


prevalence_df.to_csv(os.path.join('..', 'data', 'ncbi_tid_HMP_taxon_prevalence.csv'))

#Index(['assembly_accession', 'bioproject', 'biosample', 'wgs_master',
#      'refseq_category', 'taxid', 'species_taxid', 'organism_name',
#      'infraspecific_name', 'isolate', 'version_status', 'assembly_level',
#      'release_type', 'genome_rep', 'seq_rel_date', 'asm_name', 'submitter',
#      'gbrs_paired_asm', 'paired_asm_comp', 'ftp_path',
#      'excluded_from_refseq'],
#      dtype='object')
assembly_summary_df = pd.read_csv(os.path.join('..', 'data', 'assembly_summary.txt'), sep='\t')
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

df_merged = pd.merge(assembly_summary_df, species_df, on=['species_taxid'], how='inner')
# df_merged = pd.merge(assembly_summary_df, prevalence_df, on=['genus_taxid'], how='inner')
df_merged.to_csv(os.path.join('..', 'data', 'HMP_taxon_prevalence_download.csv'))


ftp_links = set()
# Species only no genus
# Use the uniform distribution
for type in ['Gut', 'Oral', 'Skin']:
    for i in range(5):
        dist = np.random.uniform(0, 1, df_merged.shape[0])
        mask = df_merged['%s prevalence' % type] > dist
        print('%s_%d.csv' % (type, i))
        print('Number of Unique Strains: %d' % (np.sum(mask)))
        df_merged[mask].to_csv(os.path.join('..', 'results', '%s_%d.csv' % (type, i)))
        # print('Number of Unique Species: %d' % (np.unique(df_merged[mask]['species_taxid_x']).shape[0]))
        print('Number of Unique Species: %d' % (np.unique(df_merged[mask]['species_taxid']).shape[0]))
        [ftp_links.add( 'wget ' + i + '/%s_genomic.fna.gz' % (i.split('/')[-1])) for i in df_merged['ftp_path']]

with open(os.path.join('..', 'results', 'ftp_links.txt'), 'w') as outf:
    for i in ftp_links:
        outf.write('%s\n' % i)
