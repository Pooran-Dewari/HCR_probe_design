# Extract sense mRNA sequences for HCR probe design

A pipeline for selecting the longest transcript isoform from a reference genome annotation and preparing **sense mRNA sequences** suitable for **HCR RNA-FISH probe design**.

The pipeline was developed for **Molecular Instruments HCR v3.0 chemistry workflows**, where probe sets are designed against transcript sequences.

The workflow:

1. Takes a user-supplied list of target genes.
2. Extracts all annotated mRNA transcripts using the genome FASTA and GFF3 annotation.
3. Selects the longest transcript isoform for each gene.
4. Preserves the input gene order.
5. Generates HCR-ready FASTA sequences.
6. Produces QC files showing transcript ranking and selected isoforms.
7. Carries optional biological annotations (gene description and cell identity) through to the final outputs.

---

# Features

## Transcript selection

For each requested gene:

- all annotated mRNA isoforms are extracted
- transcripts are ranked by length
- the longest transcript is selected

Example:

```
Gene       Transcript       Rank   Length
G3128      G3128.64          1      8219
G3128      G3128.11          2      6200
G3128      G3128.3           3      4100
```

The selected transcript is:

```
G3128.64
```

---

# Sequence type generated

The pipeline extracts:

```
mRNA sequence
|
|-- exons only
|-- introns removed
|-- UTRs retained
|-- mature transcript sequence
```

The output represents the processed transcript sequence from the annotation.

It is **not CDS-only**.

For example:

```
5' UTR + CDS + 3' UTR
```

are retained.

This is appropriate for HCR probe design because probes can target any region within the mature transcript.

---

# Requirements

## Software

Required:

- `bash`
- `gffread`
- `awk`
- standard Unix tools

Example:

```bash
conda install -c bioconda gffread
```

---

# Input files

## 1. Gene list

The user provides a tab-delimited file containing target genes.

The first column must be called:

```
Gene
```

Additional annotation columns are optional.

---

## Minimal input example

`genes.txt`

```text
Gene
G8841
G17277
G22387
G11503
```

---

## Annotated input example

Additional columns:

- `Description`
- `CellType`

are automatically carried into output files.

Example:

`hcr_panel.txt`

```text
Gene	Description	CellType
G8841	macrophage	Divonne
G17277	hyalio	Divonne
G22387	SGCs	Divonne
G11503	Svep1-12	GSCs
G21910	Jag2	Hepato
G13652	Kcnae	GNECs
G6819	Egfl8-2	Gill type1
G2457	Bgh3-20	Hyalinocytes
G22071	Par14-4	Haemocyte
G10190	Unchar_9062	Mantle type1
G25637	Obscn-2	Adduct
G3128	Mys-2	Adduct
G4180	Pif-7	mantle type2
G15965	Mucin-21	Mantle epi
G27503	Ca3a1	SGCs
```

---

# Reference files

The pipeline requires:

Genome:

```
Crassostrea_gigas_uk_roslin_v1.dna_sm.primary_assembly.fa
```

Annotation:

```
Crassostrea_gigas.cgigas_uk_roslin_v1.58.chr.gff3
```

The GFF3 file must contain:

```
gene
mRNA
exon
```

features.

---

# Running the pipeline

Example:

```bash
bash select_longest_mrna_for_HCR.sh hcr_panel.txt
```

---

# Output directory

The output directory is automatically created from the input filename.

Example:

Input:

```
hcr_panel.txt
```

creates:

```
hcr_panel_HCR/
```

---

# Output files

The pipeline generates three files:

```
hcr_panel_HCR/

├── transcript_ranks.tsv
├── selected_transcripts.tsv
└── selected_one_per_gene_HCR.fa
```

---

# 1. transcript_ranks.tsv

Contains all transcript isoforms for requested genes ranked by length.

Example:

```
**************************************************
GENE: G3128
**************************************************
Gene	Transcript	Rank	Length	CDS	Strand
G3128	G3128.64	1	8219	576-3686	-
G3128	G3128.11	2	6200	401-3200	-
G3128	G3128.3	3	4100	200-2500	-
```

This file provides the audit trail showing why an isoform was selected.

---

# 2. selected_transcripts.tsv

Contains the final selected transcript for each gene.

Input order is preserved.

Example:

```
Gene	Description	CellType	Transcript	Rank	Length	CDS	Strand
G8841	Unchar_9062	Mantle type1	G8841.1	1	867	1-717	+
G17277	hyalio	Divonne	G17277.19	1	1909	113-742	-
G22387	SGCs	Divonne	G22387.33	1	4620	908-3193	-
G3128	Mys-2	Adduct	G3128.64	1	8219	576-3686	-
```

---

# 3. selected_one_per_gene_HCR.fa

Final FASTA file for HCR probe design.

The FASTA header contains:

- gene ID
- description
- cell identity
- transcript ID
- transcript length
- CDS coordinates
- strand

Example:

```
>gene=G3128 desc=Mys-2 cell=Adduct transcript=G3128.64 length=8219 CDS=576-3686 strand=-
CAATTAAACATGTATTGAATAAAAGAAATTT...
```

---

# Quality control

## Input gene order

The pipeline preserves the original order supplied by the user.

Example:

Input:

```
G8841
G17277
G22387
G3128
```

Output FASTA:

```
G8841
G17277
G22387
G3128
```

This makes downstream HCR panel design and probe tracking easier.

---

## Missing genes

The pipeline checks whether every requested gene was successfully matched.

Successful example:

```
[8] Checking missing genes

No missing genes!!
```

If genes are absent:

```
Missing genes:

G12345
G67890
```

Possible causes:

- gene ID mismatch
- gene absent from annotation
- annotation version mismatch

---

# Notes on HCR probe design

The generated FASTA contains the complete mature transcript sequence.

Advantages:

- includes UTR regions
- avoids intronic sequence
- represents the biologically processed RNA molecule

For HCR v3.0 probe design, the final FASTA can be supplied directly to downstream probe design workflows.

---

_Pipeline developed for transcript selection and HCR probe preparation workflows._
