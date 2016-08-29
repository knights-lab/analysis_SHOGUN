k=(1000 10000 100000 1000000 10000000)

for IN_FILE in *.fastq; do
    fastq_to_fasta -i ${IN_FILE} -o ${IN_FILE//fastq/fna}
done

mkdir subsample

for IN_FILE in *.fna; do 
    for i in ${k[@]}; do
        # Make the directory to store down-sampling results
        for j in `seq 1 5`; do
            # An experiment
            subset_fasta -k ${i} -i ${IN_FILE} -o subsample/${IN_FILE//.fna}.${i}.$[j}.fna
        done
    done
done
