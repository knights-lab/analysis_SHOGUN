hmp_species_all.txt:
All species identified in HMP shotgun data in any body site (HMPDACC analysis).

hmp_species_gut.txt:
All species identified in HMP shotgun data in stool samples (HMPDACC analysis).

Folders:
```
gmg/
    a2t.rs81.txt: #gb_accession, taxid, green_genes_taxonomy
    miniGWG/
        miniGWG.fna: The FASTA db
        miniGWG.tax: The taxonomy mapping file ##sequence_header, green_genes_taxonomy
    miniGMG/
    megaGMG/
    test/
        miniGWG.100.fna: 100 test reference genomes
        miniGWG.100.tax: Test taxonomy mapping file
```

##### a2t.rs81.txt
```bash
# To create the GenBank Accession to Green Genes Taxonomy String Mapping File
##########################################################################################
# Accession to taxonomy
# First download
wget  ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz

# Then decompress
gunzip nucl_gb.accession2taxid.gz nucl_gb.accession2taxid

# Cut the first and 3rd columns
cut -f 1,3 nucl_gb.accession2taxid > nucl_gb.accession2taxid.13.txt

# Run the script provided by DOJO
add_green_genes_tax_to_gb_accession -i nucl_gb.accession2taxid.13.txt > ./gb2taxid.txt
# The headers are:
gb_accession    taxid   green_genes_taxonomy
```