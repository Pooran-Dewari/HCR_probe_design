#!/bin/bash

FASTA="Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa"
GFF="Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3"
GENE_LIST="genes.txt"

ALL_MRNA="all_mrna.fa"
LENGTHS="transcript_lengths.tsv"
RANKS="transcript_ranks.tsv"
KEEP_IDS="keep_ids.txt"
FINAL="selected_one_per_gene.fa"

# 1. clean gene list
tail -n +2 "$GENE_LIST" > genes.clean.txt

# 2. generate transcripts
gffread -W -w "$ALL_MRNA" -g "$FASTA" "$GFF"

# 3. extract gene + transcript lengths (robust)
awk '
function get_gene(h, m) {
    if (match(h, /gene[:=]([^ ;]+)/, m)) return m[1]
    if (match(h, /transcript:([^ .]+)/, m)) return m[1]
    return "NA"
}

NR==FNR {genes[$1]=1; next}

/^>/ {
    if (seq != "") {
        print gene "\t" tx "\t" length(seq)
    }

    header=$0
    sub(/^>/, "", header)
    sub(/ CDS=.*/, "", header)

    gene=get_gene(header, m)
    tx=header
    seq=""
    next
}

{
    seq = seq $0
}

END {
    if (seq != "") {
        print gene "\t" tx "\t" length(seq)
    }
}
' genes.clean.txt "$ALL_MRNA" > "$LENGTHS"

# 4. rank transcripts
sort -k1,1 -k3,3nr "$LENGTHS" | \
awk 'BEGIN{OFS="\t"} {
    rank[$1]++
    print $1, rank[$1], $2, $3
}' > "$RANKS"

# 5. KEEP ONLY:
#    - rank 1
#    - AND gene is in your list
awk '
NR==FNR {gene[$1]=1; next}
$2==1 && ($1 in gene) {print $3}
' genes.clean.txt "$RANKS" | \
sed 's/^>//' > "$KEEP_IDS"

# 6. extract FASTA (safe matching)
awk '
NR==FNR {
    gsub(/^>/,"",$0)
    split($0,a," ")
    keep[a[1]]=1
    next
}

/^>/ {
    h=$0
    gsub(/^>/,"",h)
    split(h,b," ")
    ok=(b[1] in keep)
}

ok {print}
' "$KEEP_IDS" "$ALL_MRNA" > "$FINAL"

echo "DONE"
echo "Final: $FINAL"
