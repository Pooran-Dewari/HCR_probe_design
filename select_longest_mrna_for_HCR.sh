#!/bin/bash

# updated: 4 Aug 2026
set -euo pipefail
trap 'echo "ERROR: Pipeline failed at line $LINENO"' ERR

echo "Script started"
echo "Running in: $(pwd)"
echo ""

############################################
# Temp dir
############################################

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT


############################################
# Input
############################################

if [ $# -ne 1 ]; then
    echo "Usage: $0 gene_list.txt"
    exit 1
fi

GENE_LIST=$1

HEADER=$(head -n1 "$GENE_LIST")

if [[ "$HEADER" != *Gene* ]]; then
    echo "ERROR: First column must be 'Gene'"
    exit 1
fi


############################################
# Reference
############################################

FASTA="Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa"
GFF="Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3"


############################################
# Output
############################################

BASE=$(basename "$GENE_LIST")
BASE=${BASE%.*}
OUTDIR="${BASE}_HCR"
mkdir -p "$OUTDIR"

RANKS="$OUTDIR/transcript_ranks.tsv"
SELECTED="$OUTDIR/selected_transcripts.tsv"
FINAL="$OUTDIR/selected_one_per_gene_HCR.fa"


############################################
# Temp files
############################################

ALL_MRNA="$TMPDIR/all_mrna.fa"
TXMAP="$TMPDIR/tx2gene.tsv"
META="$TMPDIR/meta.tsv"
GENE_INFO="$TMPDIR/gene_info.tsv"
CLEAN_GENES="$TMPDIR/genes.txt"
RANKS_RAW="$TMPDIR/ranks_raw.tsv"


echo "=============================================="
echo " HCR transcript selection + annotation"
echo "=============================================="


############################################
# 1. Parse gene input (flexible columns)
############################################

echo "[1] Parsing gene list"

awk '
NR==1 {
    for(i=1;i<=NF;i++){
        if($i=="Gene") g=i
        if($i=="Description") d=i
        if($i=="CellType") c=i
    }
    next
}

{
    gene=$g
    desc=(d ? $d : "NA")
    cell=(c ? $c : "NA")

    print gene > "'$CLEAN_GENES'"
    print gene "\t" desc "\t" cell >> "'$GENE_INFO'"
}
' "$GENE_LIST"


############################################
# 2. Extract mRNA
############################################

echo "[2] Extracting mRNA"

gffread -W -w "$ALL_MRNA" -g "$FASTA" "$GFF"


############################################
# 3. Transcript → gene
############################################

echo "[3] Mapping transcripts"

awk -F'\t' '
$3=="mRNA" {
    match($9,/ID=transcript:([^;]+)/,t)
    match($9,/Parent=gene:([^;]+)/,g)
    if(t[1] && g[1])
        print t[1] "\t" g[1]
}
' "$GFF" > "$TXMAP"


############################################
# 4. Metadata
############################################

echo "[4] Extracting metadata"

awk '
NR==FNR { map[$1]=$2; next }

/^>/ {
    if(seq!="")
        print gene "\t" tx "\t" length(seq) "\t" cds "\t" strand

    header=$0; sub(/^>/,"",header)

    match(header,/transcript:([^ ]+)/,t); tx=t[1]
    gene=map[tx]

    cds="NA"; strand="NA"
    if(match(header,/CDS=([0-9]+-[0-9]+)/,c)) cds=c[1]
    if(match(header,/loc:[^|]+\|[0-9-]+\|([+-])/,s)) strand=s[1]

    seq=""
    next
}

{ seq=seq $0 }

END {
    if(seq!="")
        print gene "\t" tx "\t" length(seq) "\t" cds "\t" strand
}
' "$TXMAP" "$ALL_MRNA" > "$META"


############################################
# 5a. Rank
############################################

echo "[5] Ranking"

awk 'NR==FNR {w[$1]; next} ($1 in w)' "$CLEAN_GENES" "$META" | \
sort -k1,1 -k3,3nr | \
awk 'BEGIN{OFS="\t"}{r[$1]++; print $1,$2,r[$1],$3,$4,$5}' \
> "$RANKS_RAW"


############################################
# 5b. Human-readable ranking report
############################################

echo "[6] Creating transcript ranking report"

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
# 6. Select longest (preserve order + annotate)
############################################

echo "[6] Selecting longest transcripts"

echo -e "Gene\tDescription\tCellType\tTranscript\tRank\tLength\tCDS\tStrand" > "$SELECTED"

awk '
NR==FNR {
    order[++n]=$1
    desc[$1]=$2
    cell[$1]=$3
    next
}

$3==1 { best[$1]=$0 }

END {
    for(i=1;i<=n;i++){
        g=order[i]
        if(g in best){
            split(best[g],f,"\t")
            print g,desc[g],cell[g],f[2],f[3],f[4],f[5],f[6]
        }
    }
}
' "$GENE_INFO" "$RANKS_RAW" >> "$SELECTED"

column -t "$SELECTED"


############################################
# 7. FASTA with annotations (FIXED)
############################################

echo "[7] Writing FASTA"

awk '
NR==FNR {
    if(FNR==1) next

    tx=$4

    gene[tx]=$1
    desc[tx]=$2
    cell[tx]=$3
    len[tx]=$6
    cds[tx]=$7
    strand[tx]=$8

    order[++n]=tx
    keep[tx]=1
    next
}

/^>/ {
    if(seq!="" && current in keep)
        seqs[current]=seq

    header=$0

    # FIX: use "m" instead of "t"
    if(match(header,/transcript:([^ ]+)/,m))
        current=m[1]
    else
        current=""

    seq=""
    next
}

{
    seq=seq $0
}

END {
    if(current in keep)
        seqs[current]=seq

    for(i=1;i<=n;i++){

        tx=order[i]

        print ">gene="gene[tx] \
              " desc="desc[tx] \
              " cell="cell[tx] \
              " transcript="tx \
              " length="len[tx] \
              " CDS="cds[tx] \
              " strand="strand[tx]

        print seqs[tx]
    }
}
' "$SELECTED" "$ALL_MRNA" > "$FINAL"

############################################
# 8. Missing gene report
############################################

echo "[8] Checking missing genes"

awk 'NR>1 {print $1}' "$SELECTED" | sort > "$TMPDIR/found.txt"
sort "$CLEAN_GENES" > "$TMPDIR/input.txt"


MISSING=$(comm -23 "$TMPDIR/input.txt" "$TMPDIR/found.txt")


echo ""

if [ -z "$MISSING" ]; then

    echo "No missing genes!!"

else

    echo "Missing genes:"
    echo "$MISSING"

fi

############################################
# DONE
############################################

echo ""
echo "=============================================="
echo " COMPLETE"
echo "=============================================="

echo ""
echo "Outputs:"
echo "$RANKS"
echo "$SELECTED"
echo "$FINAL"
