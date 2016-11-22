from snakemake.utils import min_version
from snakemake.utils import makedirs

min_version("3.8.2")

### scripts
script_path = "scripts"

### import snakemake modules
include: "data/Snakefile"

rule all:
	input: results
