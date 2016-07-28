k=(1000 10000 100000 1000000 10000000)

for IN_FILE in *.fastq; do 

    # Grab the entire number of reads once for downsampling
    NUM_READS="$(grep -c "^>" ${IN_FILE})"

    mkdir ${IN_FILE//.fastq/}

    for i in ${k[@]}; do
        # Make the directory to store down-sampling results
        test -d ${TRIAL_HOME}/hits_${i} | mkdir -p ${TRIAL_HOME}/hits_${i}
        for j in `seq 1 5`; do
            # An experiment
            subset_fasta.py -n ${NUM_READS} -k ${i} ${IN_FILE} > ${IN_FILE//.fastq/}/i.j.${IN_FILE}
        done
    done
done