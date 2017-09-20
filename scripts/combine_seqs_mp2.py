#!/usr/bin/env python
from __future__ import print_function, division
import argparse
import os
import re
from collections import defaultdict

TRUE_FALSE_DICT = {
    "True": True,
    "False": False,
    "true": True,
    "false": False,
    "T": True,
    "F": False,
    "t": True,
    "f": False,
    "1": True,
    "0": False,
    "TRUE": True,
    "FALSE": False
}


def make_arg_parser():
    parser = argparse.ArgumentParser(description='This is the commandline interface for combine_seqs',
                                     usage='combine_seqs v0.0.1 -i <input> -o <output> ...')
    parser.add_argument('-i', '--input', help='Set the directory path of the fastq directory', required=True)
    parser.add_argument('-o', '--output', help='Set the directory path of the output to place the combined_seqs.fna (default: cwd)', default=os.getcwd())
    parser.add_argument('-s', '--strip_underscore', help='Prune sample names after the first underscore (default: %(default)s)',default="False")
    parser.add_argument('-t', '--type', help='FASTQ or FASTA', choices=['FASTA', 'FASTQ'], default='FASTA')
    parser.add_argument('--debug', help='Retain all intermediate files (default: Disabled)', dest='debug', action='store_true')
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
    yield title.strip(), data


def read_fastq(fh):
    # Assume linear FASTQS
    while True:
        title = next(fh)
        while title[0] != '@':
            title = next(fh)
        # Record begins
        if title[0] != '@':
            raise IOError('Malformed FASTQ files, verify they are linear and contain complete records.')
        title = title[1:].strip()
        sequence = next(fh).strip()
        garbage = next(fh).strip()
        if garbage[0] != '+':
            raise IOError('Malformed FASTQ files, verify they are linear and contain complete records.')
        qualities = next(fh).strip()
        if len(qualities) != len(sequence):
            raise IOError('Malformed FASTQ files, verify they are linear and contain complete records.')
        yield title, sequence


def format_basename(filename):
    if TRUE_FALSE_DICT[STRIP]:
        parts = os.path.basename(filename).split('_')
        if len(parts) == 1:
            return re.sub('[^0-9a-zA-Z]+', '.', '.'.join(parts[0].split('.')[:-1]))
        else:
            appendage = ''
            for section in parts[1:]:
                if section.find("R1") != -1:
                    appendage = 'R1'
                elif section.find("R2") != -1:
                    appendage = 'R2'
            return re.sub('[^0-9a-zA-Z]+', '.', parts[0])+appendage
    else:
        return re.sub('[^0-9a-zA-Z]+', '.', '.'.join(os.path.basename(filename).split('.')[:-1]))


# Given a string, and start and end string, return the sandwiched string within the the original string

def find_between(s, first, last):
    try:
        start = s.index(first) + len(first)
        end = s.index(last, start)
        return s[start:end]
    except ValueError:
        return ""

def convert_combine(inputs, run_type, output_path):
    output_filename = os.path.join(output_path, 'combined_seqs.fna')
    with open(output_filename, 'w') as outf_fasta:
        for path in inputs:
                counter = defaultdict(int)
                seqs = 0
                basename = format_basename(path)
                with open(path) as inf:
                    if run_type == "FASTA":
                        gen = read_fasta(inf)
                    else:
                        gen = read_fastq(inf)
                    
                    for i, (title, seq) in enumerate(gen):
                        if not seq.count("N") > 10:
                            outf_fasta.write('>%s_%i %s\n%s\n' % (basename, i, title, seq))
                            seqs += 1
                            ncbi_tid = find_between(title, 'ncbi_tid|', '|')
                            counter[ncbi_tid] += 1
                    print('%s\t%s\t%d' % (path, basename, seqs))
                    keys = list(counter.keys())
                    print("\t".join(keys))
                    print("\t".join((str(counter[_]) for _ in keys)))
    return [output_filename]


def main():
    parser = make_arg_parser()
    args = parser.parse_args()

    global STRIP
    STRIP = args.strip_underscore
    global DEBUG
    DEBUG = args.debug

    # FIRST CHECK IF THE INPUT AND OUTPUT PATH EXIST. IF DO NOT, RAISE EXCEPTION AND EXIT
    if not os.path.exists(args.input):
        raise ValueError('Error: Input directory %s doesn\'t exist!' % args.input)

    if not os.path.exists(args.output):
        os.makedirs(args.output)

    mode = args.type

    if mode == 'FASTA':
        paths = [os.path.join(args.input, f) for f in os.listdir(args.input) if f.endswith('fasta') or f.endswith('fna') or f.endswith('fa') or f.endswith('fn')]
    else:
        paths = [os.path.join(args.input, f) for f in os.listdir(args.input) if f.endswith('fastq') or f.endswith('fq')]

    convert_combine(paths, args.type, args.output)

if __name__ == '__main__':
    main()
