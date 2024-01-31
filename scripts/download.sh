# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <url> <output_directory> [yes/no] [filter_keyword]"
    exit 1
fi

url="$1"
output_directory="$2"
uncompress="$3"
filter_keyword="$4"

# Create the output directory if it doesn't exist
mkdir -p "$output_directory"

# Download the file
#curl -o "$output_directory/$(basename "$url")" "$url"

if [ -e "$output_file" ]; then
    echo "File $output_file already exists. Skipping download."
else
    # Download the file
    curl -o "$output_directory/$(basename "$url")" "$url"

    # Check if the download was successful
    if [ "$?" -ne 0 ]; then
        echo "Error downloading the file from $url"
        exit 1
    fi
fi

# Check if the download was successful
if [ "$?" -ne 0 ]; then
    echo "Error downloading the file from $url"
    exit 1
fi

# Uncompress the file if specified
if [ "$uncompress" == "yes" ]; then
    gunzip "$output_directory/$(basename "$url")"
fi

echo "Download and processing completed successfully."

