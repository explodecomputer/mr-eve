# devtools::install_github("MRCIEU/TwoSampleMR@mr_structure")
library(TwoSampleMR)
library(tidyverse)

ds <- "01"

load(paste0("../results/", ds, "/outcome_nodes.rdata"))
load(paste0("../results/", ds, "/exposure_dat.rdata"))

i <- as.numeric(commandArgs(T)[1])

load(paste0("../results/01/dat/dat-", outcome_nodes$id[i], ".rdata"))
d$outcome <- outcome_nodes$trait[i]

m1 <- run_mr(subset(d, id.exposure != id.outcome))
save(m1, file=paste0("../results/01/mr/m1-", outcome_nodes$id[i], ".rdata"))
m2 <- run_mr(subset(d, id.exposure != id.outcome & steiger_dir & steiger_pval < 0.05))
save(m2, file=paste0("../results/01/mr/m2-", outcome_nodes$id[i], ".rdata"))

