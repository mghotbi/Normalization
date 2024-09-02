#!/bin/bash

# Step 1: Input Parameters
BAM_DIR="./bam_files"  # Directory containing the BAM files
OUTPUT_DIR="./relative_abundance"  # Output directory
METAGENOME_SIZE=1000000  # Replace with the actual size of each metagenome in bases

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Step 2: Convert BAM files to relative abundance table using BamM
for BAM_FILE in $BAM_DIR/*.bam; do
    SAMPLE_NAME=$(basename $BAM_FILE .bam)
    OUTPUT_FILE="$OUTPUT_DIR/${SAMPLE_NAME}_relative_abundance.tsv"

    # Use BamM to calculate coverage and convert to relative abundance
    BamM cov -b $BAM_FILE --tpmean --length > $OUTPUT_FILE

    # Step 3: Normalize for the size of each metagenome in bases and contig length
    python3 <<EOF
import pandas as pd

# Load data
data = pd.read_csv('$OUTPUT_FILE', sep='\t')

# Normalize coverage values
data['normalized_coverage'] = (data['tpmean'] / $METAGENOME_SIZE) / data['contig_length']

# Apply filters: coverage > 80% of contig length and coverage >= 5x
data_filtered = data[(data['tpmean'] >= 0.8 * data['contig_length']) & (data['tpmean'] >= 5)]

# Save the filtered data
data_filtered.to_csv('$OUTPUT_DIR/${SAMPLE_NAME}_filtered.tsv', sep='\t', index=False)
EOF

done

echo "Relative abundance calculation completed."
