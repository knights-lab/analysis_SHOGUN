from snakemake.utils import min_version
from snakemake.utils import makedirs
import os

min_version("3.11.2")

## Include the config
include: "config.py"

results = expand("{path}/{name}_table.txt", path = result_path, name = "indices_time_and_memory")

include: "references/Snakefile"

rule all:
  input: results