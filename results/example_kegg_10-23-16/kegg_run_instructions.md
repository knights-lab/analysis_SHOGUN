```
# Former ugly, bash for loop to align everything with bowtie2, I made a new script called 'shogun_bowtie' should do the job instead.
for f in /export/scratch/ben/serghei/afterQCFasta/*; do echo "bowtie2 --no-unal -x /project/flatiron/tonya/img_bowtie_builds/img.gene.bacteria.bowtie -S ${$(basename $f)//.fastq/.sam} --np 0 --mp "1,1" --rdg "0,1" --rfg "0,1" --score-min "L,0,-0.02" --norc -f $f  --very-sensitive -k 8 -p 24 --no-hd" >! bowtie_img_align.txt; done

# New way to run it
shogun_bt2_lca -i /export/scratch/ben/serghei/afterQCFasta -o <output directory> -l False -b /project/flatiron/tonya/img_bowtie_builds/img.gene.bacteria.bowtie

# Input is a folder of SAM files, one SAM file per sample
# Should be aligned against img.genes.bacteria found here
kegg_parse_img_ids -i /project/flatiron/ben/data/ribo/img_genes_aligned/ -o kegg.csv

# Input file is the KEGG csv file from the kegg_parse_img_ids
# -m was created a long time ago
kegg_predictions -i ./kegg.csv -o ./kegg.intersection.csv  --algorithm intersection -m /project/flatiron/data/img/img-gene-ko-map.txt
```
