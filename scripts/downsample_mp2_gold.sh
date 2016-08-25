k=(1000 10000 100000 1000000 10000000)

for IN_FILE in *.fastq; do 

    fastq_to_fastq -i ${IN_FILE} -o ${IN_FILE//fastq/fna}

    for i in ${k[@]}; do
        # Make the directory to store down-sampling results
        for j in `seq 1 5`; do
            # An experiment
            subset_fasta -k ${i} -i ${IN_FILE//fastq/fna} -o ${IN_FILE//.fastq}.i.j.fna
        done
    done
done
