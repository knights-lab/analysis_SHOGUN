for file in *.fastq.gz
do
    source deactivate
    7z x $file -o shi7en_tmp/
    source activate shi7en
    shi7en -SE --combine_fasta False -i shi7en_tmp -o shi7en_tmp/R1_QC --adaptor Nextera -trim_l 50
    source activate shogun
    shogun_bt2_lca -i shi7en_tmp/R1_QC -o shi7en_tmp/R1_QC/shogun_bt2_lca_out -l False -b /project/flatiron2/data/img/annotated/genes_bt2/img.genes
    source deactivate
    rm shi7en_tmp/*.fastq
    rm shi7en_tmp/R1_QC/*.fna
done