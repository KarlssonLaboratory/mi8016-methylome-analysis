#!/usr/bin/env Rscript

# ~~ Code description ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# get number of cores for process
# import genexp table
# extract the unique genes
# plot the gene counts per gene, include all generations in the same plot
# show significance indicators within the plots
# use log10 scale on y-axis, ylimits depend on number of sign. indicators
# add gene name and gene function to title and caption, respectively
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

suppressPackageStartupMessages({
  library(methylKit)
  library(readr)
  library(scales)
  library(matrixStats)
})

ncores <- 10


### Find all coverages files and make a metadata ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

files <- list.files(
  path = "results/",
  pattern = "*.cov.gz",
  full.names = TRUE,
  recursive = TRUE
)
files <- normalizePath(files)

meta <- data.frame(
  path = files,
  sample = sub(".*Sample_UA-2815-(.+)_R\\d+_.*", "\\1", files),
  id = NA,
  treatment = 0
)
meta$treatment[grep("C", meta$sample)] <- 0
meta$treatment[grep("PFOS-1-", meta$sample)] <- 1
meta$id[grep("C", meta$sample)] <- "control"
meta$id[grep("PFOS-1-", meta$sample)] <- "PFOS"

# Only use control and PFOS 1µM samples
meta <- subset(meta, treatment %in% c(0, 1))


### Built a methylObj ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

filelist <- split(as.character(meta$path), seq_along(meta$path))
samplelist <- split(as.character(meta$id), seq_along(meta$id))

obj <- methRead(
  location = filelist,
  sample.id = samplelist,
  treatment = meta$treatment,
  header = FALSE,
  assembly = "GRCh38",

  # "amp", "bismark","bismarkCoverage", "bismarkCytosineReport"
  pipeline = "bismarkCoverage"
)

# Filter CpG-site position that match the ref genome
cpg_pos <- read_lines("data/cpg_positions.txt.gz")

for (i in seq_along(obj)) {
  cat(" > Filtering sample :", i, "\n")

  cpgs <- paste0(obj[[i]]$chr, ":", obj[[i]]$start)
  rows <- cpgs %in% cpg_pos

  obj[[i]] <- obj[[i]][rows, ]
}

# Filter reads
obj <- filterByCoverage(
  obj,
  lo.count = 10,  # < 10
  hi.perc = 99.9  # the top 99th percentile (PCR duplicates)
)

# Normalisation:
# Scaling factor between samples based on differences between median
# of coverage distribution
obj <- normalizeCoverage(
  obj,
  method = "median"
)


# Make methylation table ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Use 60% of all samples per group as minimum per CpG-site
nsamples <- 0.6
nsamples <- as.integer(ceiling(mean(table(meta$treatment)) * nsamples))

cat(" > Minimum number of samples per group:", nsamples, "\n")

meth <- methylKit::unite(
  obj,
  min.per.group = nsamples,
  mc.cores = ncores
)

# Remove CpG-sites with low variation, std < 2
mat <- percMethylation(meth)
std <- matrixStats::rowSds(mat, na.rm = TRUE)
meth <- meth[std > 2]

cat(" >", comma(sum(std < 2)), "CpG-sites removed (due to low variation)\n")
cat(" >", comma(nrow(meth)), "CpG-sites remains post filtering\n")

# Save table w/ methylation percentage for each sample per CpG-site
dmr_id <- paste0(getData(meth)$chr, ":", getData(meth)$start)
betavalues <- percMethylation(meth)
rownames(betavalues) <- dmr_id
filename <- "betavalues.Rds"
saveRDS(betavalues, file = file.path("data", filename))


### Calculate differentially methylated regions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dat <- calculateDiffMeth(
  meth,
  adjust = "SLIM",
  #effect = "predicted",
  overdispersion = "MN",
  test = "Chisq",
  mc.cores = ncores
)

# convert to dataframe
data <- getData(dat)

# add type and cpg_id
data$type <- ifelse(data$meth.diff > 0, "hyper", "hypo")
#data$chr <- paste0("chr", data$chr)
data$dmr_id <- paste0(data$chr, ":", data$start)
data$feature <- "cpg"
data$num_cpg <- 1


### Save output

filename <- "diffmeth.csv.gz"
write_csv(data, file = file.path("data", filename))

# stats
out <- c(
  nrow = nrow(data),
  sign_0.05 = nrow(subset(data, qvalue <= 0.05)),
  sign_0.01 = nrow(subset(data, qvalue <= 0.01)),
  sign_0.05_15 = nrow(subset(data, qvalue <= 0.05 & abs(meth.diff) >= 15)),
  sign_0.01_15 = nrow(subset(data, qvalue <= 0.01 & abs(meth.diff) >= 15))
)

print(out)
