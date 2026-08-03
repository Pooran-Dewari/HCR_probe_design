# Extract Sense mRNA Sequence for HCR Probe Design

A pipeline to extract **sense mRNA sequences** from a genome annotation (GFF3 + genome FASTA) for **HCR RNA-FISH probe design**.

The script is designed for annotations where each gene can have multiple transcript isoforms. It identifies all mRNA isoforms, ranks them by transcript length, selects the longest transcript per gene, and produces a clean FASTA file suitable for submission to probe design platforms such as Molecular Instruments HCR v3.0.

---

## Overview

For each gene of interest:

1. Read a user-supplied gene list.
2. Extract all annotated mRNA transcripts from the genome.
3. Build the correct gene → transcript relationship from the GFF3 annotation.
4. Calculate transcript lengths.
5. Rank isoforms within each gene.
6. Select the longest transcript isoform.
7. Generate:
   - a transcript ranking report for quality control
   - a selected transcript table
   - a clean FASTA file for HCR probe design

---

## Why select the longest transcript?

HCR RNA-FISH probe design benefits from longer target sequences because:

- longer transcripts provide more possible probe binding sites
- more binding sites generally improve signal strength
- longest isoforms often provide the most sequence space for probe design

However, the longest transcript is not necessarily the most highly expressed isoform. For projects with isoform-specific biology, transcript expression data should be considered.

---

# Requirements

## Software

The pipeline requires:

- `gffread`
- standard Unix tools:
  - `awk`
  - `sort`
  - `column`

Install `gffread` using Conda:

```bash
conda install -c bioconda gffread
---

### Inputs

#### Genome FASTA
Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa  

#### GFF3 annotation
Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3  

#### Gene list (one per line)  
gene id  
G3840  
G3842  
G9893  

---

### Outputs

| File | Description |
|------|-------------|
| `selected_one_per_gene.fa` | Final FASTA (one transcript per gene) |
| `transcript_lengths.tsv` | Transcript length QC table |
| `transcript_ranks.tsv` | Isoform ranking per gene |
| `all_mrna.fa` | All transcripts (intermediate file) |

---
### How?
Save genes in a file, e.g. genes_order1.txt
Download and run the `get_mRNA.sh` bash script as follows.

bash get_mRNA.sh genes_order1.txt
Output files will be saved in genes_order1/ dirctory.

---

### Biological interpretation

- Output sequences are **spliced mRNA transcripts**
- Strand information is applied (reverse-complemented for − strand genes)
- Sequences represent **transcriptionally correct mRNA**
- Final output provides a **single representative isoform per gene (longest transcript)**

---


### Notes

- Longest isoform is a **computational representative**, not necessarily biologically dominant
- Accuracy depends on quality of GFF3 annotation (UTRs improve transcript completeness)
- Works best with well-annotated eukaryotic genomes

---

### Example output
G3840 → G3840.2 (selected longest isoform)  
G3842 → G3842.3 (selected longest isoform)  
G9893 → G9893.1 (single isoform gene)  
