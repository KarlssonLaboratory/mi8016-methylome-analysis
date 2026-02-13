#!/usr/bin/env Rscript

# ~~ Code description ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Generate figure 3 from paper:
# https://doi.org/10.1016/j.scitotenv.2024.174864
# Figure shows pathway enrichment results with GO terms matching the following
# keywords:
# > motor
# > actin
# > adhesion
# > growth
# > collagen
# > myosin
# > microtubule
# > cytoskeletal
# > junction
# > extracellular
# > locomotion
# These keywords are matched against the gene description and are relevant
# genes for PFOS induced phenotypes (previous paper)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(cowplot)
})


# Import datasets
go <- readRDS("data/PFOS_MCF-10A_GO.Rds")

keywords <- c(
  "motor",
  "actin",
  "adhesion",
  "growth",
  "collagen",
  "myosin",
  "microtubule",
  "cytoskeletal",
  "junction",
  "extracellular",
  "locomotion"
)

### Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

filter_by_keywords <- function(go) {
  x <- go$Description

  rows <- sapply(keywords, function(word) {
    grep(word, x)
  }) |> unlist() |> unique()

  go[rows, ]
}

plot_go_res <- function(res, title = NULL, keywords = TRUE, N_goterms = 10, N = 40, base_size = 10, size = 8, legends = FALSE) {

  if (keywords) res$go <- filter_by_keywords(res$go)
  go_terms <- res$go$ONTOLOGY |> unique()

  # keep only N of goterms
  rows <- lapply(go_terms, function(x) {
    rows <- which(res$go$ONTOLOGY %in% x)
    if (length(rows) > N_goterms) rows <- rows[1:N_goterms]
    return(rows)
  }) |> unlist()

  data <- res$go[rows, ]

  ggplot(data, aes(reorder(Description, Count), Count, fill = ONTOLOGY)) +
    geom_segment(aes(
      x = reorder(Description, Count), 
      xend = reorder(Description, Count),
      y = 0,
      yend = Count),
      lwd = 1) +
    geom_point(size = 4.5, shape = 21, color = "black") +
    geom_text(aes(label = Count), size = 2, col = "black") +
    coord_flip() +
    scale_fill_brewer(palette = "Set2") +
    scale_color_continuous(labels = scales::label_scientific()) +
    facet_grid(ONTOLOGY ~ ., scales = "free", space = "free") +
    theme_linedraw(base_size) +
    theme(
      axis.text.y = element_text(size = size),
      plot.title = element_text(hjust = 0.5)) +
    { if (!legends) guides(fill = "none", color = "none") } +
    scale_y_continuous(labels = scales::comma_format(accuracy = 1)) +
    labs(
      title = title,
      x = "",
      y = "Number of genes in GO term",
      fill = "GO terms",
      color = "q-value")
}

### Generate plots ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

p_promoter <- plot_go_res(go$promoter, title = "Promoter")
p_exon <- plot_go_res(go$exon, title = "Exon")
p_cgi <- plot_go_res(go$cgi, title = "CGIs")


### Save figure ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

p <- plot_grid(
  p_promoter,
  p_exon,
  p_cgi,
  ncol = 1,
  rel_heights = c(0.2, 1.1, 0.55),
  labels = "AUTO",
  align = "v"
)

filename <- "figure3.png"

ggsave(
  filename = filename,
  path = "images",
  plot = p,
  width = 7,
  height = 10,
  bg = "white",
  create.dir = TRUE
)

cat(paste(
  "\n~~ figure1.R complete ~~~~~~~~~~~~~~~~~~~~~~~~~~",
  "\n > Output\t:", filename,
  "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n"
))