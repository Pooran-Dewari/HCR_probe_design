# Extract Sense mRNA Sequence for HCR Probe Design

A pipeline to extract **sense mRNA sequences** from a genome annotation (GFF3 + genome FASTA) for **HCR RNA-FISH probe design**.

The script identifies transcript isoforms per gene, ranks them by length, selects the longest isoform, and generates a clean FASTA file ready for submission to probe design platforms such as Molecular Instruments HCR v3.0.

---

## Overview

For each gene of interest:

1. Read a user-supplied gene list
2. Extract all annotated mRNA transcripts
3. Map transcripts to genes using GFF3 (`Parent=gene`)
4. Calculate transcript lengths
5. Rank isoforms within each gene
6. Select the longest transcript
7. Generate outputs for QC and probe design

---

## Why select the longest transcript?

* Provides more probe binding sites
* Improves signal strength in HCR RNA-FISH
* Maximizes usable sequence space

⚠️ Note: The longest isoform is not always the most biologically relevant. Use expression data if isoform specificity matters.

---

## Requirements

### Software

* `gffread`
* `awk`
* `sort`
* `column`

Install `gffread`:

```bash
conda install -c bioconda gffread
```

---

## Input files

### 1. Genome FASTA

Example:

```
Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa
```

---

### 2. GFF3 annotation

Example:

```
Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3
```

Must contain:

```
ID=transcript:XXXX;
Parent=gene:XXXX;
```

Example:

```
LR761634.1 ROSLIN_INST mRNA ... ID=transcript:G3689.1;Parent=gene:G3689
```

---

### 3. Gene list

Example: `hcr_order1.txt`

```
Gene
G3128
G3690
G4501
G5021
```

The first line is treated as a header and removed.

---

## Usage

```bash
./select_longest_mrna_for_HCR.sh hcr_order1.txt
```

---

## Output

The script creates:

```
hcr_order1_HCR/
```

### 1. selected_one_per_gene_HCR.fa

Final FASTA for probe design.

Example:

```
>gene=G3128 transcript=G3128.64 length=8219 CDS=576-3686 strand=-
CAATTAAACATGTATTGAATAAA...
```

---

### 2. selected_transcripts.tsv

Selected isoform per gene:

```
Gene    Transcript    Rank    Length    CDS          Strand
G3128   G3128.64      1       8219      576-3686     -
G3690   G3690.2       1       5210      400-2800     +
```

---

### 3. transcript_ranks.tsv

Full ranking:

```
Gene    Transcript    Rank    Length    CDS    Strand

**************************************************
GENE: G3128
**************************************************
G3128   G3128.64      1       8219      576-3686     -
G3128   G3128.63      2       6100      540-3100     -
```

---

## Workflow

```
GFF3 + Genome FASTA
        |
   Extract mRNA
        |
 Map transcript → gene
        |
 Compute transcript length
        |
 Rank per gene
        |
 Select longest isoform
        |
 HCR-ready FASTA
```

---

## Notes

### mRNA sequence

* Exons only
* Introns removed
* Represents mature transcript

---

### Sense orientation

Sequences are in transcript (sense) orientation:

```
5' → 3' mRNA
```

---

### Isoform selection

Example:

```
G3128.64   8219 bp
G3128.63   6100 bp
G3128.62   4300 bp
```

Selected:

```
G3128.64
```

---

## Example workflow

```bash
./select_longest_mrna_for_HCR.sh hcr_order1.txt
```

Inspect:

```bash
less hcr_order1_HCR/selected_transcripts.tsv
less hcr_order1_HCR/transcript_ranks.tsv
```

Submit:

```
hcr_order1_HCR/selected_one_per_gene_HCR.fa
```

---

## Designed for

* HCR RNA-FISH probe design
* Ensembl-style GFF3 annotations
* Multi-isoform genomes

Example use case:

**Pacific oyster (*Crassostrea gigas*) HCR v3.0 probe design**

---

## Author

Pipeline developed for transcript selection and HCR probe preparation workflows.
