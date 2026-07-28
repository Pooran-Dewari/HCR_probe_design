### Commands below to find location of a given DNA sequence using genome fasta and gff3 file.  

First get the location of the DNA sequence and save in bed format  
```
seqkit locate -p "AAACAGACCTATGGACCTTTACGA" *primary_assembly.fa  --bed > typ-1-loc.bed
```
Now, use bedtools to intersect with the gff3 file to retrive annotation 
```
bedtools intersect -a *gff3 -b typ-1-loc.bed -wb > typ-1-genes.txt
```
Extract gene ID info
```
awk -F'\t' '
{
    gene=""

    if(match($9,/gene_id=([^;]+)/,a))
        gene=a[1]

    else if(match($9,/Parent=gene:([^;]+)/,a))
        gene=a[1]

    else if(match($9,/Parent=transcript:([^;]+)/,a))
        gene=a[1]

    else if(match($9,/ID=gene:([^;]+)/,a))
        gene=a[1]

    print $1"\t"$4"\t"$5"\t"$3"\t"gene
}' typ-1-genes.txt
```
If you just want the gene ID for entries 'genes'
```
awk -F'\t' '$3=="gene" {
    match($9,/gene_id=([^;]+)/,a);
    print $1"\t"$3"\t"$4"\t"$5"\t"a[1]
}' typ-1-genes.txt

```
