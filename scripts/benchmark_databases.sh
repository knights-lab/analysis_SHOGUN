#!/usr/bin/env bash

# Build the UTree Database


usr/bin/time -v sh -c 'utree-build {input.fasta} {input.tax} {wildcards.output_path}/{wildcards.basename}.ubt {threads}; utree-compress {wildcards.output_path}/{wildcards.basename}.ubt {output.ctr}' >> {output.benchmark} 2>&1