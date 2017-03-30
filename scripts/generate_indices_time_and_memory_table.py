#!/usr/bin/env python
import sys

f = open(sys.argv[1], "rU")

total = 0
for line in f:
    if line[0] == ">":
        continue

    total += len(line) - 1

print(total)
