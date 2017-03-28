from snakemake.utils import min_version
from snakemake.utils import makedirs
import os

min_version("3.11.2")

## Include the config
include("config.py")
