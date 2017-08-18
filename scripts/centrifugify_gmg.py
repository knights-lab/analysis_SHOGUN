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
	with open(snakemake.input.tax[0]) as inf:
		csv_inf = csv.reader(inf, delimiter='\t')
		for row in csv_inf:
			title = row[0].split(".")[0]
			if title in accession2taxid:
				row[1] = accession2taxid[title]
				csv_outf.writerow(row)
