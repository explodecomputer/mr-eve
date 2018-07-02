library(tidyverse)
library(TwoSampleMR)
library(MRInstruments)

## Soma scan proteins

data(mrbase_instruments)
exposure_dat <- mrbase_instruments
ao <- available_outcomes()


nodes <- subset(ao, id %in% exposure_dat$id.exposure) %>% 
	dplyr::select(id, trait, pmid, author, consortium, category, subcategory, sample_size, ncase, ncontrol, unit, sd) 
nodes$id <- as.character(nodes$id)
nodes$type <- "eo"
save(nodes, file="../results/03/nodes.rdata")
