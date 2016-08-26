#wget -qO- ftp://ftp.ncbi.nlm.nih.gov/refseq/release/bacteria/*.genomic.fna.gz | gunzip -c | linearize_fasta | grep -A 1 -f genus_list_hmp.txt >> bacteria_hmp.fna
#wget -qO- ftp://ftp.ncbi.nlm.nih.gov/refseq/release/viral/*.genomic.fna.gz | gunzip -c | python /project/flatiron/ben/NINJA-DOJO/ninja_dojo/scripts/refseq_annotate.py -i - --output ./virus.complete.fna --prefixes NC,AC
#wget -qO- ftp://ftp.ncbi.nlm.nih.gov/refseq/release/protozoa/*.genomic.fna.gz | gunzip -c | linearize_fasta >> protozoa.fna
#wget -qO- ftp://ftp.ncbi.nlm.nih.gov/refseq/release/fungi/*.genomic.fna.gz | gunzip -c | linearize_fasta >> fungi.fna
#wget -qO- ftp://ftp.ncbi.nlm.nih.gov/refseq/release/archaea/*.genomic.fna.gz | gunzip -c | linearize_fasta >> archaea.fna
#wget -qO- ftp://ftp.ncbi.nlm.nih.gov/refseq/release/plant/*.genomic.fna.gz | gunzip -c | linearize_fasta >> plant.fna


# bacteria need to be one-by-one
#wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/bacteria/*.genomic.fna.gz
for file in /project/flatiron02/data/refseq/bacteria/bacteria.*genomic.fna.gz; do gunzip -c $file | python /project/flatiron/ben/NINJA-DOJO/ninja_dojo/scripts/refseq_annotate.py -i - --prefixes NC,AC -o - >> ./bacteria.complete.fna; done
#python /project/flatiron/ben/NINJA-DOJO/ninja_dojo/scripts/refseq_annotate.py /project/flatiron02/data/refseq/bacteria/bacteria.fna --output ./bacteria.complete.fna --prefixes NC,AC
