#Download all the files specified in data/filenames
for url in $(<data/urls); do
    bash scripts/download.sh $url data
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes #TODO

# Index the contaminants file
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

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

cat log/cutadapt/*.log > log/pipeline.log

echo "Pipeline completed successfully."
