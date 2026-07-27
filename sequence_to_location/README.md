### Commands below to find location of a given DNA sequence using genome fasta and gff3 file.  

First get the location of the DNA sequence and save in bed format  
```
seqkit locate -p "AAACAGACCTATGGACCTTTACGA" *primary_assembly.fa  --bed > typ-1-loc.bed
```
Now, use bedtools to intersect with the gff3 file to retrive annotation 
```
bedtools intersect -a *gff3 -b typ-1-loc.bed -wb > typ-1-genes.txt
```
