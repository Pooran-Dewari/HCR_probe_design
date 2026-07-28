#!/bin/bash

# This bash script takes a query FASTA file, randomly selects 30 unique 20-nt sequences,
# searches for these sequences in the target genome assembly, and uses the corresponding
# GFF3 annotation file to identify overlapping genes.
#
# Example use case:
# If you have an aquaporin-8 sequence from one oyster species and want to identify
# the corresponding gene(s) in the Crassostrea gigas genome assembly:
#
# 1. Save the query FASTA file as:
#    aquaporin-8.query
#
# 2. Run:
#    bash find_target_genes.sh aquaporin-8.query
#
# The script will:
#   - generate random 20-nt sequence queries from the input FASTA
#   - locate matching sequences in the genome assembly
#   - annotate matching genomic regions using the GFF3 file
#   - extract the corresponding gene IDs
#
# Output:
#   - a table of sequence hits and annotated gene IDs
#   - an R-compatible gene list ready for Seurat expression visualisation
#   - see 




#################################################
# Reference files
#################################################

GENOME="Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa"
GFF="Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3"


#################################################
# Input FASTA
#################################################

FASTA=$1

if [ -z "$FASTA" ]; then
    echo "Usage: $0 gene.fa"
    exit 1
fi


PREFIX=$(basename "$FASTA" .query)

QUERY="${PREFIX}.generated.query"
OUT="${PREFIX}.target_gene_results.txt"
RFILE="${PREFIX}.gene_list.txt"


#################################################
# Generate random 20 nt sequences
#################################################

echo "Generating random sequences..."

SEQ=$(grep -v "^>" "$FASTA" | tr -d '\n')

LEN=${#SEQ}

echo -e "id\tsequence" > "$QUERY"


count=1
declare -A seen

while [ $count -le 30 ]
do

    START=$(( RANDOM % (LEN-20) + 1 ))

    S=$(echo "$SEQ" | cut -c${START}-$((START+19)))

    if [[ -z "${seen[$S]}" ]]; then

        echo -e "${PREFIX}-seq${count}\t${S}" >> "$QUERY"

        seen[$S]=1
        count=$((count+1))

    fi

done


echo "Created:"
echo "$QUERY"


#################################################
# Search genome and extract genes
#################################################

echo "Finding genomic locations..."

echo -e "target_id\tsequence\tchr\tfeature\tstart\tend\tgene_id" > "$OUT"


tail -n +2 "$QUERY" | while IFS=$'\t' read id seq
do

    echo "Processing $id"


    seqkit locate \
        -p "$seq" \
        "$GENOME" \
        --bed > tmp.bed


    awk -v id="$id" -v seq="$seq" \
    'BEGIN{OFS="\t"} {$4=id; $5=seq; print}' \
    tmp.bed > tmp2.bed


    bedtools intersect \
        -a "$GFF" \
        -b tmp2.bed \
        -wb > tmp.intersect


    awk -F'\t' -v id="$id" -v seq="$seq" '
    $3=="gene" {
        match($9,/gene_id=([^;]+)/,a);
        print id"\t"seq"\t"$1"\t"$3"\t"$4"\t"$5"\t"a[1]
    }' tmp.intersect >> "$OUT"


done


rm -f tmp.bed tmp2.bed tmp.intersect


#################################################
# Create R gene list
#################################################

echo "Saving R gene list..."

echo -n "gene_list <- c(" > "$RFILE"

cut -f7 "$OUT" | \
tail -n +2 | \
grep -v "^$" | \
sort -u | \
awk '{printf "\"%s\",",$1}' | \
sed 's/,$//' >> "$RFILE"

echo ")" >> "$RFILE"


echo ""
echo "Finished"
echo "Generated query:"
echo "$QUERY"
echo "Results:"
echo "$OUT"
echo "R list:"
echo "$RFILE"
cat "$RFILE"
