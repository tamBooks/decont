# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).

#!/bin/bash
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <sample_directory> <output_directory> <sample_id>"
    exit 1
fi

sample_directory="$1"
output_directory="$2"
sample_id="$3"

# Merge all files from the given sample into a single file
cat "$sample_directory/$sample_id"*.fastq.gz > "$output_directory/$sample_id.fastq.gz"

echo "Merging completed successfully."

