#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(BSgenome.Hsapiens.UCSC.hg38)
  library(readr)
})

# namespace = Hsapiens / BSgenome.Hsapiens.UCSC.hg38
genome <- BSgenome.Hsapiens.UCSC.hg38

# select chromosomes
chromosomes <- paste0("chr", c(1:22, "M", "X", "Y"))

# empty list to fill
cpg <- list()

# iterate over chosen chromosomes
for (chrom in chromosomes) {
  cat(paste("\r > Counting CG motifs for :", chrom))

  out <- matchPattern("CG", genome[[chrom]])
  out <- as.data.frame(out)
  out$chr <- chrom

  cpg[[chrom]] <- out # Save in a list
}

# convert list to data frame
cpg <- Reduce(function(x, y) rbind(x, y), cpg)

cpg_vector <- paste0(cpg$chr, ":", cpg$start)

#cpg <- cpg[, c("chr", "start", "end", "seq")]
#cpg$id <- paste0(cpg$chr, ":", cpg$start)

if (!dir.exists("data")) dir.create("data")

filename <- "cpg_positions.txt.gz"

#write_csv(cpg, file = file.path("data", filename))
write_lines(cpg_vector, file = file.path("data", filename))

cat(paste(
  "\n ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n",
  " > cpg_positions.R complete\n",
  " >", filename, "generated",
  "\n\n ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n"
))
