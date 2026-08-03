#!/bin/bash

####### 3 aug 2026 ###############################################

set -euo pipefail

trap 'echo "ERROR: Pipeline failed at line $LINENO"' ERR

echo "Script started"
echo "Running in: $(pwd)"
echo ""


############################################
# Create temporary directory
############################################

TMPDIR=$(mktemp -d)

trap 'rm -rf "$TMPDIR"' EXIT


############################################
# USER INPUT
############################################

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo "  $0 gene_list.txt"
    exit 1
fi

GENE_LIST=$1


############################################
# Validate gene list
############################################

if [ "$(head -n1 "$GENE_LIST")" != "Gene" ]; then
    echo "ERROR: First line of gene list must be:"
    echo "Gene"
    exit 1
fi


############################################
# REFERENCE FILES
############################################

FASTA="Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa"
GFF="Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3"


############################################
# OUTPUT DIRECTORY
############################################

BASE=$(basename "$GENE_LIST")
BASE=${BASE%.*}

OUTDIR="${BASE}_HCR"

mkdir -p "$OUTDIR"


############################################
# Temporary working files
############################################

ALL_MRNA="$TMPDIR/all_mrna.fa"
TXMAP="$TMPDIR/transcript_gene_map.tsv"
META="$TMPDIR/transcript_metadata.tsv"
CLEAN_GENES="$TMPDIR/genes.clean.txt"
RANKS_RAW="$TMPDIR/transcript_ranks_raw.tsv"


############################################
# Output files
############################################

RANKS="$OUTDIR/transcript_ranks.tsv"
SELECTED="$OUTDIR/selected_transcripts.tsv"
FINAL="$OUTDIR/selected_one_per_gene_HCR.fa"



echo "=============================================="
echo " HCR transcript selection pipeline"
echo " Input: $GENE_LIST"
echo " Output: $OUTDIR"
echo "=============================================="


############################################
# 1. Clean gene list
############################################

echo ""
echo "[1] Cleaning gene list"

tail -n +2 "$GENE_LIST" > "$CLEAN_GENES"



############################################
# 2. Extract all mRNA
############################################

echo ""
echo "[2] Extracting mRNA sequences"

gffread \
-W \
-w "$ALL_MRNA" \
-g "$FASTA" \
"$GFF"



############################################
# 3. Transcript -> gene map
############################################

echo ""
echo "[3] Building transcript-gene map"


awk -F'\t' '

$3=="mRNA" {

    match($9,/ID=transcript:([^;]+)/,tx)
    match($9,/Parent=gene:([^;]+)/,gene)

    if(tx[1] && gene[1])
        print tx[1] "\t" gene[1]
}

' "$GFF" > "$TXMAP"



############################################
# 4. Transcript metadata
############################################

echo ""
echo "[4] Extracting transcript metadata"


awk '

NR==FNR {

    tx2gene[$1]=$2
    next

}


/^>/ {


    if(seq!="")
        print gene "\t" tx "\t" length(seq) "\t" cds "\t" strand


    header=$0
    sub(/^>/,"",header)


    match(header,/transcript:([^ ]+)/,t)

    tx=t[1]

    gene=tx2gene[tx]


    if(match(header,/CDS=([0-9]+-[0-9]+)/,c))
        cds=c[1]
    else
        cds="NA"


    if(match(header,/loc:[^|]+\|[0-9-]+\|([+-])/,s))
        strand=s[1]
    else
        strand="NA"


    seq=""
    next

}


{
    seq=seq $0
}


END {

    if(seq!="")
        print gene "\t" tx "\t" length(seq) "\t" cds "\t" strand

}

' "$TXMAP" "$ALL_MRNA" > "$META"



############################################
# 5. Rank transcripts for requested genes
############################################

echo ""
echo "[5] Ranking transcripts"


awk '

NR==FNR {
    wanted[$1]=1
    next
}

($1 in wanted)

' "$CLEAN_GENES" "$META" | \

sort -k1,1 -k3,3nr | \

awk '

BEGIN{OFS="\t"}

{
    rank[$1]++
    print $1,$2,rank[$1],$3,$4,$5
}

' > "$RANKS_RAW"



############################################
# 6. Create ranking report
############################################

echo ""
echo "[6] Creating ranking report"


awk '

$1 != previous {

    if(previous!="")
        print ""

    print "**************************************************"
    print "GENE: " $1
    print "**************************************************"

    print "Gene\tTranscript\tRank\tLength\tCDS\tStrand"

    previous=$1

}

{
    print

}

' "$RANKS_RAW" > "$RANKS"



############################################
# 7. Select longest isoforms
############################################

echo ""
echo "[7] Selecting longest isoforms"
echo ""


echo -e "Gene\tTranscript\tRank\tLength\tCDS\tStrand" > "$SELECTED"


awk '
$3==1 {
    print
}
' "$RANKS_RAW" >> "$SELECTED"



echo "Selected isoforms:"
echo ""

column -t "$SELECTED"


############################################
# 8. Generate ordered HCR FASTA
############################################

echo ""
echo "[8] Creating ordered HCR FASTA"


awk '

NR==FNR {

    if(FNR==1)
        next

    wanted[$2]=1
    gene[$2]=$1
    len[$2]=$4
    cds[$2]=$5
    strand[$2]=$6

    order[++n]=$2

    next

}


/^>/ {


    if(seq!="" && current in wanted)
        sequence[current]=seq


    header=$0
    sub(/^>/,"",header)


    match(header,/transcript:([^ ]+)/,t)

    current=t[1]

    seq=""

    next

}


{
    seq=seq $0

}


END {

    if(current in wanted)
        sequence[current]=seq


    for(i=1;i<=n;i++){

        tx=order[i]

        print ">gene="gene[tx] \
              " transcript="tx \
              " length="len[tx] \
              " CDS="cds[tx] \
              " strand="strand[tx]

        print sequence[tx]

    }

}

' "$SELECTED" "$ALL_MRNA" > "$FINAL"



############################################
# 9. Summary
############################################

echo ""
echo "=============================================="
echo " COMPLETE"
echo "=============================================="


echo ""
echo "Genes supplied:"
tail -n +2 "$GENE_LIST" | wc -l


echo ""
echo "Selected transcripts:"
grep -c "^>" "$FINAL"


if [ "$(tail -n +2 "$SELECTED" | wc -l)" -ne "$(grep -c "^>" "$FINAL")" ]; then
    echo ""
    echo "WARNING: Selected transcript table and FASTA count differ"
fi


echo ""
echo "Files created:"
echo ""
echo "$RANKS"
echo "$SELECTED"
echo "$FINAL"


echo ""
echo "FASTA example:"
head -1 "$FINAL"


echo ""
echo "Script finished successfully"
