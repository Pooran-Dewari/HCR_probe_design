# HCR probe design for Pacific oyster genes

### Gene-Specific Longest mRNA Extraction Pipeline

This repository provides a reproducible bioinformatics pipeline to extract **one representative mRNA transcript per gene (longest isoform)** from a genome assembly and GFF3 annotation file.

The pipeline is designed for large eukaryotic genomes and performs strand-aware, exon-based transcript reconstruction, followed by isoform ranking and gene-level filtering.

---

### What this pipeline does

Requires these files at ready:
- A genome FASTA file  
- A GFF3 annotation file  
- A list of gene IDs of interest  

the pipeline:

1. Extracts **spliced mRNA sequences** (exons joined, introns removed)
2. Applies correct **strand-aware reconstruction**
3. Computes **transcript lengths**
4. Groups transcripts by **gene ID**
5. Ranks isoforms by length
6. Selects the **longest transcript per gene**
7. Filters results using the provided gene list
8. Outputs:
   - Final FASTA (one mRNA per gene)
   - Transcript length table (QC)
   - Ranking table per gene (QC)

---

### Requirements

- gffread (Cufflinks/StringTie suite)  
- awk (GNU awk recommended)  
- sort, grep, sed (standard Unix tools)

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

Download and run the get_mRNA.sh bash script  

---

### Biological interpretation

- Output sequences are **spliced mRNA transcripts**
- Strand information is applied (reverse-complemented for − strand genes)
- Sequences represent **transcriptionally correct mRNA**
- Final output provides a **single representative isoform per gene (longest transcript)**

---

### Use cases

- Comparative genomics
- Gene-level summarisation
- Orthology mapping
- Protein prediction pipelines
- Transcriptome simplification for downstream analysis

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
