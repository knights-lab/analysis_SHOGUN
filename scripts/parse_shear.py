#!/usr/bin/env python
# Usage parse_shear sequences.fna a2t.txt emb_output.b6
import sys
import csv
from collections import Counter, defaultdict

sequences = sys.argv[1]
accession2taxonomy = sys.argv[2]
alignment = sys.argv[3]

with open(accession2taxonomy) as inf:
    next(inf)
    csv_inf = csv.reader(inf, delimiter="\t")
    a2t = dict(('_'.join(row[0].split()[0].split('_')[:-1]).split('.')[0], row[-1]) for row in csv_inf)
print("Loaded accession2taxonomy.")

reads_counter = Counter()
with open(sequences) as inf:
    for i, line in enumerate(inf):
        if i % 100000 == 0:
            print("Processed %d lines" % i)
            print(line)
        if line.startswith('>'):
            name = '_'.join(line.split()[0][1:].split('_')[:-1]).split('.')[0]
            if name in a2t:
                species = a2t[name]
                reads_counter.update([species])

print("Loaded read counter")

counts_dict = defaultdict(Counter)
with open(alignment) as inf:
    csv_inf = csv.reader(inf, delimiter="\t")
    for i, row in enumerate(csv_inf):
        if i % 100000 == 0:
            print("Processed %d records" % i)
            print(row)
        if row[-1].startswith('k'):
            read = row[0]
            read = "_".join(read.split('_')[:-1]).split('.')[0]
            if read in a2t:
                species = a2t[read]
                tax = row[-1]
                counts_dict[species].update([tax])

print("Loaded counts_dict.")

with open("sheared_bayes.txt", "w") as outf:
    for i, species in enumerate(counts_dict.keys()):
        row = [0] * 10
        row[-1] = reads_counter[species]
        row[0] = species
        counts = counts_dict[species]
        if i % 10000 == 0:
            print("Processed %d records" % i)
            print(counts)
        for j in counts.keys():
            c = j.count(';')
            row[c+1] = counts[j]
        row = list(map(str, row))
        outf.write("\t".join(row) + "\n")
