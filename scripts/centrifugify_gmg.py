#!/usr/bin/env python
from ninja_utils.parsers import FASTA
import csv

accession2taxid = dict()
with open(snakemake.input.mapping) as inf:
	csv_inf = csv.reader(inf, delimiter='\t')
	next(csv_inf)
	for line in csv_inf:
		accession2taxid[line[0]] = line[1]

with open(snakemake.output[0], 'w') as outf:
	csv_outf = csv.writer(outf, delimiter='\t')
	with open(snakemake.input.tax) as inf:
		csv_inf = csv.reader(inf, delimiter='\t')
		for row in inf:
			row[1] = accession2taxid[row[0]]
			csv_outf.writerow(row)
