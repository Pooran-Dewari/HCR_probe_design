## 🧬 HCR RNA-FISH Probe Design Pipeline

### Extract, validate and prepare transcript sequences for HCR v3.0 probe design

This workflow describes how to generate, validate and submit transcript sequences
for **Molecular Instruments HCR RNA-FISH v3.0 probe design**.

The pipeline starts from a list of target genes and produces mature mRNA sequences
that can be directly submitted for HCR probe design.

The workflow has three stages:

1. **Extract the correct transcript sequences from the genome annotation**
2. **Validate each transcript sequence using NCBI BLAST**
3. **Submit the final FASTA file to Molecular Instruments for probe design**

---

### Table of Contents

- [Workflow Overview](#workflow-overview)
- [Stage 1: Extract HCR-ready mRNA sequences](#stage-1-extract-hcr-ready-mrna-sequences)
  - [Requirements](#requirements)
  - [Input Files](#input-files)
  - [Reference Files](#reference-files)
  - [Running the Pipeline](#running-the-pipeline)
  - [Output Files](#output-files)
- [Stage 2: Validate FASTA sequences before ordering](#stage-2-validate-fasta-sequences-before-ordering)
  - [NCBI BLAST validation](#ncbi-blast-validation)
  - [Expected BLAST result](#expected-blast-result)
- [Stage 3: Submit sequences for HCR probe design](#stage-3-submit-sequences-for-hcr-probe-design)
- [Notes](#notes)

---

### Workflow Overview

```
Target gene list
        |
        ▼
Genome FASTA + GFF3 annotation
        |
        ▼
Extract all mRNA transcripts
        |
        ▼
Rank transcript isoforms
        |
        ▼
Select longest transcript
        |
        ▼
Generate HCR FASTA sequences
        |
        ▼
Validate using NCBI BLAST
        |
        ▼
Submit to Molecular Instruments
```

---

### Stage 1: Extract HCR-ready mRNA sequences

#### Overview

Genes often contain multiple transcript isoforms.

For reliable HCR probe design, this pipeline selects the **longest annotated
mRNA transcript** for each target gene.

For every requested gene:

- all annotated mRNA isoforms are extracted
- transcripts are ranked by length
- the longest transcript is selected
- original gene order is preserved
- mature transcript FASTA sequences are generated
- quality-control files are produced

---

#### Requirements

##### Software

Required:

| Software | Purpose |
|---|---|
| bash | Run pipeline |
| gffread | Extract transcript sequences |
| awk | Parse annotation |
| Unix tools | File processing |

Install `gffread`:

```bash
conda install -c bioconda gffread
```

---

#### Input Files

##### 1. Gene list

The input file must contain a column called:

```
Gene
```

Example:

`hcr_panel.txt`

```text
Gene
G8841
G17277
G22387
G11503
G3128
```

---

##### Optional annotations

Additional columns can be included.

These are carried through to the final output.

Example:

```text
Gene	Description	CellType
G8841	Unchar_9062	Mantle type1
G17277	hyalio	Divonne
G22387	SGCs	Divonne
G3128	Mys-2	Adduct
```

Supported additional information:

- gene description
- cell identity
- experimental annotation

---

#### Reference Files

The pipeline requires:

##### Genome FASTA

```
Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa
```

##### Genome annotation

```
Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3
```

The GFF3 annotation must contain:

```
gene
mRNA
exon
```

features.

---

#### Running the Pipeline

Run:

```bash
bash select_longest_mrna_for_HCR.sh hcr_panel.txt
```

The output directory is automatically created.

Example:

Input:

```
hcr_panel.txt
```

Output:

```
hcr_panel_HCR/
```

---

#### Output Files

The pipeline generates:

```
hcr_panel_HCR/

├── transcript_ranks.tsv
├── selected_transcripts.tsv
└── selected_one_per_gene_HCR.fa
```

---

#### Understanding the Output

##### 1. transcript_ranks.tsv

Contains all transcript isoforms ranked by length.

Example:

```text
Gene	Transcript	Rank	Length	CDS	Strand

G3128	G3128.64	1	8219	576-3686	-
G3128	G3128.11	2	6200	401-3200	-
G3128	G3128.3	3	4100	200-2500	-
```

This provides an audit trail showing why a transcript was selected.

---

##### 2. selected_transcripts.tsv

Contains the final transcript selected for each gene.

Example:

```text
Gene	Description	CellType	Transcript	Length

G3128	Mys-2	Adduct	G3128.64	8219
```

---

##### 3. selected_one_per_gene_HCR.fa

This is the FASTA file used for validation and probe design.

Example:

```text
>gene=G3128 desc=Mys-2 cell=Adduct transcript=G3128.64 length=8219 CDS=576-3686 strand=-

CAATTAAACATGTATTGAATAAAAGAAATTT...
```

The FASTA contains:

- gene ID
- transcript ID
- transcript length
- CDS coordinates
- strand information

---

#### Sequence Type Generated

The pipeline extracts the mature transcript sequence.

```
5' UTR
   |
   CDS
   |
3' UTR
```

Included:

✅ Exons  
✅ UTR regions  
✅ Coding sequence  

Removed:

❌ Introns  
❌ Intergenic sequence  

The final sequence represents the processed mRNA molecule.

---

### Stage 2: Validate FASTA sequences before ordering

Before submitting sequences for HCR probe design, each transcript should be
validated.

The goal is to confirm:

- sequence corresponds to the expected gene
- transcript belongs to the correct species
- orientation is correct

---

#### NCBI BLAST validation

##### Step 1

Open:

https://blast.ncbi.nlm.nih.gov/Blast.cgi

---

##### Step 2

Copy one FASTA entry from:

```
selected_one_per_gene_HCR.fa
```

Example:

```
>gene=G3128 desc=Mys-2 cell=Adduct transcript=G3128.64

CAATTAAACATGTATTGAATAAAAGAAATTT...
```

Copy only the sequence.

---

##### Step 3

Select database:

```
RefSeq RNA
```

---

##### Step 4

Run BLAST.

---

##### Step 5

Check species match

In the BLAST results:

Open the:

```
Magallana gigas
```

matching transcript result.

---

##### Step 6

Confirm strand orientation

The alignment must show:

```
Strand: Plus / Plus
```

Expected:

```
Query      Plus
Subject    Plus
```

---

##### Step 7

Save validation record

Go to:

```
Downloads
      |
      ▼
Text (aligned sequences)
```

Save the alignment result.

---

### Stage 3: Submit sequences for HCR probe design

After validation, submit:

```
selected_one_per_gene_HCR.fa
```

to:

**Molecular Instruments**

for:

```
HCR RNA-FISH v3.0 probe design
```

The FASTA should contain:

- validated transcript sequences
- one sequence per gene
- mature mRNA sequences
- correct species annotation

---

### Final Workflow Summary

```
1.
Run pipeline

select_longest_mrna_for_HCR.sh

        ↓

Generate

selected_one_per_gene_HCR.fa


2.
Validate sequences

NCBI BLAST
        ↓
RefSeq RNA
        ↓
Magallana gigas
        ↓
Confirm Plus/Plus strand


3.
Submit FASTA

        ↓

Molecular Instruments

        ↓

HCR RNA-FISH v3.0 probes
```

---

### Notes

- The pipeline does not select CDS-only sequences.
- UTR regions are retained because HCR probes can target any accessible region
  of the mature transcript.
- Selecting the longest transcript provides a reproducible strategy when multiple
  isoforms exist.
- BLAST validation is recommended before ordering probes to avoid transcript
  annotation errors.

---

**Pipeline developed for transcript selection and HCR RNA-FISH v3.0 probe preparation workflows.**
