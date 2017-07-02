#!/usr/bin/env python
import numpy as np
import math
import csv

def time_to_seconds(time):
    split_time = time.split(':')
    modifier = math.pow(60, len(split_time)-1)
    seconds = 0
    for time_part in split_time:
        seconds += (float(time_part) * modifier)
        modifier /= 60
    return seconds

rows = [('seconds_wall_clock', 'kbyte_memory', 'percent_cpu', 'hours_cpu', 'tool')]
for file_path in snakemake.input:
	tool = file_path.split("_")[-2]
	wall_clocks = []
	memories = []
	percent_cpus = []
	elapsed = []
	with open(file_path) as inf:
		for line in inf:
			line = line.strip()
			if 'Elapsed (wall clock)' in line:
				wall_clocks.append(time_to_seconds(line.split()[-1]))
			if 'Maximum resident set size' in line:
				memories.append(int(line.split()[-1])) 
			if 'Percent of CPU this job got' in line:
				percent_cpus.append(int(line.split()[-1][:-1]))
	cpu_hours = (np.array(wall_clocks)/3600.)*(np.array(percent_cpus)/100.)
	m = np.argmin(cpu_hours)
	rows.append((wall_clocks[m], memories[m], percent_cpus[m], cpu_hours[m], tool))

with open(snakemake.output[0], 'w') as outf:
	csv = csv.writer(outf, delimiter='\t')
	csv.writerows(rows)
