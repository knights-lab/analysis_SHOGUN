import os

## Define variables

BASE = "/project/flatiron2/ben/projects/analysis_SHOGUN"
N_THREADS = 96

### scripts
script_path = os.path.join(BASE, "scripts")

### tools
### Only non-conda tools
tool_path = os.path.join(BASE, "tools")

### data
data_path = os.path.join(BASE, "data")

### results
result_path = os.path.join(BASE, "results")
reference_path = os.path.join(result_path, "refs")

utree_ref_path = os.path.join(reference_path, "utree")
