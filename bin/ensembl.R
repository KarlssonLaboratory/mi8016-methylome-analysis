#!/usr/bin/env Rscript

organism_dataset <- "hsapiens_gene_ensembl"
mart_version <- "115"

cat(paste(
  "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n",
  "Download the gene info from the ensembl database\n\n",
  " > only keep the annotated chromosomes\n",
  " > reference genome:\t", organism_dataset, "\n",
  " > Biomart version:\t", mart_version,
  "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
))

suppressPackageStartupMessages({
  library(biomaRt)
  library(gtools)
  library(readr)
  library(scales)
})

# listEnsembl() # list available datasets
# ver <- listEnsembl()
# ver <- unlist(strsplit(ver$version[1], " "))[3]
# mart <- useEnsembl(biomart="genes") # download all gene lists
# searchDatasets(mart=mart, pattern="mus") # identify house mouse dataset
# mart <- useEnsembl(biomart = "genes", dataset = "mmusculus_gene_ensembl")
# listAttributes(mart) # list of available attributes

# get mart
mart <- useEnsembl(
  biomart = "genes",
  dataset = organism_dataset,
  version = mart_version,
  verbose = TRUE
)

# columns to import
cols <- c(
  "external_gene_name",
  "chromosome_name",
  "start_position",
  "end_position",
  "strand",
  "description",
  "gene_biotype",
  "ensembl_gene_id",
  "entrezgene_id"
)

# import & sort columns
ens <- getBM(
  mart = mart,
  attributes = cols,
  verbose = TRUE
)
ens <- ens[, cols]

cat("\n > Building ensembl table...\n")

# Only one entrez ID per ensembl ID, use the first
ens <- ens[!duplicated(ens$ensembl_gene_id), ]

# Rename columns
colnames(ens) <- c(
  "gene_name",
  "chr",
  "start",
  "end",
  "strand",
  "gene_info",
  "gene_type",
  "gene_id",
  "entrez_id"
)

ens$chr <- paste0("chr", ens$chr)
ens$strand <- ifelse(ens$strand > 0, "+", "-")
ens$size <- ens$end - ens$start

# Only save annotated chromosomes
chrom <- grep("\\.|\\_", unique(ens$chr), value = TRUE)
ens <- subset(ens, !chr %in% chrom)

# Sort chromosomes
ens <- ens[mixedorder(paste0(ens$chr, "_", ens$start)), ]

# Remove un-needed info in gene_info column
ens$gene_info <- sapply(ens$gene_info, function(x) {
  gsub(" \\[.*\\]", "", x)
})

# Reduce gene number of types

# collapse pseudogenes
ens$gene_type2 <- ens$gene_type
rows <- grep("pseudo", ens$gene_type2)
ens$gene_type2[rows] <- "pseudogene"
non_coding_RNA <- c(
  "snoRNA",
  "misc_RNA",
  "sRNA",
  "scaRNA",
  "snoRNA",
  "snRNA",
  "scRNA"
)
rows <- ens$gene_type %in% non_coding_RNA
ens$gene_type2[rows] <- "ncRNA"

# 400+ IG / TR genes hid in protein coding
rows <- grep("_gene", ens$gene_type2)
ens$gene_type2[rows] <- "protein_coding"

# Alter column order
ens <- ens[, c(
  "gene_name",
  "chr",
  "start",
  "end",
  "strand",
  "size",
  "gene_id",
  "entrez_id",
  "gene_info",
  "gene_type",
  "gene_type2"
)]

filename <- "ensembl_table.csv.gz"

write_csv(ens, file = file.path("data", filename))

cat(paste(
  "\n~~ ensembl.R complete ~~~~~~~~~~~~~~~~~~~~~~~~~~",
  "\n > Output\t:", filename,
  "\n > Num. genes\t:", comma(nrow(ens)),
  "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n"
))