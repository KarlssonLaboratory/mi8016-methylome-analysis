# Research Trends in Toxicology

This repo holds the files for the **Methylome Analysis** lecture in the _Research Trends in Toxicology course_

# Agenda

+ Reproduce figure 1 and 2 from the [PFOS EM-seq paper](https://doi.org/10.1016/j.scitotenv.2024.174864).
  + Show the process from FASTQ-files => coverage-files => table (csv)
    + Make slide to follow-along for this
  + Use the table to generate figure 1 and 2
    + Make slide to follow-along for this
  + Write stand along code to reproduce the figures
  


# Computational analysis

## Alignment & coverage

+ alignment to the reference genome
+ calculation of the coverage of the CpG-sites

Output: coverage files (`*.cov.gz`)

## Differential methylation analysis

Identify:

+ **D**ifferentially **M**ethylated **R**egions (DMRs)
+ **D**ifferentially **M**ethylated **G**enes (DMGs), DMRs are overlay with genomic positions and any overlapping genes is concidored a DMG.
+ Enriched gene ontology terms

For this we need to complete these steps:

1. Map CpG-sites, `cpg_positions.txt.gz`.
2. Ensembl dataset, `ensembl_dataset.csv.gz`.
3. Calculate differentially methylated regions (CpG-sites).
4. Overlap with genomics regions (promoter, exon, CpG-islands) to find differentially methylated genes.
5. Calculate gene ontology enrichment scores w/ over-representation analysis.
6. Generate a figure for the enriched gene ontology terms.

## 1. CpG-sites on the genome

Extract the exact positions of `CG`-motifs in the human genome, save as text file `data/cpg_positions.txt.gz`. This table will be used to filter out only the CpG-sites for downstream analysis. To generate the file run this in the terminal (or run the script inside Positron / Rstudio):

```sh
Rscript bin/cpg_positions.R
```

The script requires the following R-packages: `BSgenome.Hsapiens.UCSC.hg38` and `readr`.

<details>
  <summary>How to install R-packages</summary>

  > Assuming you have R already installed
  
  Basic R-packages are installed from [CRAN](https://cran.r-project.org/) (`install.packages()`) while bioinformatic R-packages are installed from [Bioconductor](https://bioconductor.org/) (`BiocManager::install()`). In order, to install from Bioconductor we need first to install the [Bioconductor Manager](https://bioconductor.org/install/), see code below:
  
  ```r
  # Install Bioconductor manager
  install.packages("BiocManager")
  
  # Install from CRAN
  install.packages("readr")
  
  # Install from Bioconductor
  BiocManager::install("BSgenome.Hsapiens.UCSC.hg38")
  ```
  
  Install packages like this will download the latest version. Exact version numbers are important for reproducibility.
</details>

<details>
  <summary>Run code with containers</summary>

  Use a singularity container with a pre-install environment (OS, R, packages). Run with apptainer / singularity

  ```sh
  # Save container as a variable
  METH_SIF='library://andreyhgl/singularity-r/methylome'

  # Run the container
  apptainer exec $METH_SIF Rscript bin/cpg_positions.R
  ```
</details>

Will generate `data/cpg_positions.txt.gz`.


## 2. Ensembl dataset

Will generate `data/ensembl_dataset.csv.gz`.

## 3. Calculate differentially methylated regions

We will focus on the CpG-sites, but still call them regions.

This script is computationally heavy: requires 500Gb ram, 10 cpus and runs for 1,5h. Hence, it's best ran on a computer cluster, like [UPPMAX](https://www.uu.se/centrum/uppmax/resurser/kluster). 

```sh
Rscript bin/diffmeth.R
```

Will generate `data/diffmeth.csv.gz`.

---


Make a table containing all the differentially methylated CpG-sites.

Run: `bin/diffmeth.R` (`sbatch diffmeth.slurm`), generates `table.csv`

```sh
# Testing in interaction session, 500Gb and 10 cpus needed
# salloc is custom script
salloc 5:00:00 500 10

#METH_SIF='library://andreyhgl/singularity-r/methylome'
apptainer shell $METH_SIF
```

---


