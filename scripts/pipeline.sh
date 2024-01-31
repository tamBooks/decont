
#Download all the files specified in data/filenames
for url in $(<data/urls); do
    bash scripts/download.sh $url data
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes #TODO

grep -v "small nuclear" res/contaminants.fasta > res/contaminants_filtered.fasta

# Index the contaminants file
bash scripts/index.sh res/contaminants_filtered.fasta res/contaminants_idx

# Merge the samples into a single file
for sid in $(ls data/*.fastq.gz | sed 's/.*\///' | cut -d'.' -f1 | sort -u); do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
# cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
#     -o <trimmed_file> <input_file> > <log_file>

for fname in out/merged/*.fastq.gz; do
    sid=$(basename "$fname" | cut -d'.' -f1)
    mkdir -p log/cutadapt
    cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
        -o "out/trimmed/$sid.trimmed.fastq.gz" "$fname" > "log/cutadapt/$sid.log"
done

# TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz; do
    sid=$(basename "$fname" | cut -d'.' -f1)
    mkdir -p "out/star/$sid"
    STAR --runThreadN 4 --genomeDir res/contaminants_idx \
       --outReadsUnmapped Fastx --readFilesIn "$fname" \
       --readFilesCommand gunzip -c --outFileNamePrefix "out/star/$sid/$sid."
done

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in 

echo "Pipeline log start" > log/pipeline.log

echo "Writing Pipeline log"

for sampleid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::' | sort | uniq)
do
    {
        echo "SAMPLE: $sampleid"
        echo " "
        
        echo "CUTADAPT: "
        grep -hi -e "Reads with adapters" log/cutadapt/$sampleid.log 
        grep -hi -e "total basepairs" log/cutadapt/$sampleid.log 
        echo " "
        
        echo "STAR: "
        grep -hi -e "Uniquely mapped reads %" out/star/$sampleid/${sampleid}_Log.final.out 
        grep -hi -e "% of reads mapped to multiple loci" out/star/$sampleid/${sampleid}_Log.final.out 
        grep -hi -e "% of reads mapped to too many loci" out/star/$sampleid/${sampleid}_Log.final.out 
        echo " "
    } >> log/pipeline.log

done

echo "Pipeline log Compelte"

echo "Pipeline completed successfully."

bash scripts/cleanup.sh

