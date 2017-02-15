#!/usr/bin/env bash
python scripts/create_prevalence_communities.py -p data\HMP_taxon_prevalence.csv -a data\assembly_summary.txt -o results\170214-genus
python scripts/get_genome_lengths.py" -p results/170214-simulation/genomes -o results/170214-genome_lengths

# simulate communites
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\gut_0.csv -o results\170214-gut_0
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\gut_1.csv -o results\170214-gut_1
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\gut_2.csv -o results\170214-gut_2
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\oral_0.csv -o results\170214-oral_0
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\oral_1.csv -o results\170214-oral_1
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\oral_2.csv -o results\170214-oral_2
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\skin_0.csv -o results\170214-skin_0
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\skin_1.csv -o results\170214-skin_1
python scripts/simulate_community.py -g results\170214-genome_lengths\genome_lengths.json -a results\170214-genus\skin_2.csv -o results\170214-skin_2