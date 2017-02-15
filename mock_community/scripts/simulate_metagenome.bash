#!/usr/bin/env bash
python scripts/create_prevalence_communities.py -p data/HMP_taxon_prevalence.csv -a data/assembly_summary.txt -o results/170214-genus

scripts/get_genome_lengths.py" -p results/170214-simulation/genomes -o results/170214-genome_lengths

# simulate communites
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Gut_0.csv -o results/170214-gut_0
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Gut_1.csv -o results/170214-gut_1
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Gut_2.csv -o results/170214-gut_2
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Oral_0.csv -o results/170214-oral_0
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Oral_1.csv -o results/170214-oral_1
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Oral_2.csv -o results/170214-oral_2
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Skin_0.csv -o results/170214-skin_0
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Skin_1.csv -o results/170214-skin_1
python scripts/simulate_community.py -g results/170214-genome_lengths/genome_lengths.json -a results/170214-genus/Skin_2.csv -o results/170214-skin_2