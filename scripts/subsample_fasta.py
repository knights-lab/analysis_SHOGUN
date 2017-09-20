#!/usr/bin/env python
import argparse
import random
import sys



def make_arg_parser():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-i', '--input_fasta_fp', required=True, help='Path to the input fasta file')
    parser.add_argument('-o', '--output_fp', help='The output filepath', default='-')
    parser.add_argument('-p', '--percent_subsample', help='The number of sequences to keep', default=.05, type=float)
    parser.add_argument('-s', '--seed', help="The seed of the random number generator", type=int)
    return parser

def read_fasta(fh):
    """
    :return: tuples of (title, seq)
    """
    title = None
    data = None
    for line in fh:
        if line[0] == ">":
            if title:
                yield (title.strip(), data)
            title = line[1:]
            data = ''
        else:
            data += line.strip()
    if not title:
        yield None
    yield (title.strip(), data)



def filter_fasta(fasta_gen, percent_id):
    for title, data in fasta_gen:
        if random.random() <= percent_id:
            yield title, data


def subset_fasta():
    parser = make_arg_parser()
    args = parser.parse_args()

    if args.seed:
        random.seed(args.seed)

    with open(args.input_fasta_fp) as inf:
        fasta_gen = read_fasta(inf)
        filtered_fasta_gen = filter_fasta(fasta_gen, args.percent_subsample)
        with open(args.output_fp, 'w') if args.output_fp != '-' else sys.stdout as outf:
            for title, data in filtered_fasta_gen:
                outf.write('>%s\n%s\n' % (title, data))

if __name__ == '__main__':
    subset_fasta()