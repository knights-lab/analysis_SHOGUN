#!/usr/bin/env python
import ipdb
from ninja_utils.parsers import FASTA
import csv

accession2taxid = dict()
with open(snakemake.input.mapping) as inf:
	csv_inf = csv.reader(inf, delimiter='\t')
	next(csv_inf)
	for line in csv_inf:
		accession2taxid[line[0]] = line[1]

with open(snakemake.output[0], 'w') as outf:
	with open(snakemake.input.fasta[0]) as inf:
		parser = FASTA(inf)
		for title, seq in parser.read():
			rowname = title.split(".")[0]
			if  rowname in accession2taxid:
				taxid = accession2taxid[rowname]
				outf.write('>%s|kraken:taxid|%s\n%s\n' % (title, taxid, seq))
