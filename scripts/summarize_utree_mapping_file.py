#!/usr/bin/env python
# This scripts takes in a UTree mapping file and counts the occurrence of each taxonomy at a certain level
import csv
from collections import defaultdict
import argparse
import sys


def make_arg_parser():
    parser = argparse.ArgumentParser(description='Get least common ancestor for alignments in unsorted BAM/SAM file')
    parser.add_argument('-i', '--input', help='The folder containing the SAM files to process.', required=True, type=str)
    parser.add_argument('-o', '--output', help='If nothing is given, then STDOUT, else write to file')
    parser.add_argument('-d', '--depth', help='Depth to summarize at.', default=7, type=int)
    return parser


def main():
    parser = make_arg_parser()
    args = parser.parse_args()
    counter = defaultdict(int)
    with open(args.input) if args.input else sys.stdin as inf:
        csv_reader = csv.reader(inf, delimiter="\t")
        for line in csv_reader:
            counter['; '.join(line[1].split('; ')[:args.depth])] += 1

    with open(args.output, 'w') if args.output else sys.stdout as outf:
        for key, value in counter.items():
            outf.write('%s,%d\n' % (key, value))

if __name__ == '__main__':
    main()
