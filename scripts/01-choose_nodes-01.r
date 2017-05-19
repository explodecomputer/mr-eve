library(tidyverse)

ao <- read_csv("../data/ao.csv")
ids <- scan("../results/01/ids.txt")

nodes <- subset(ao, id %in% ids) %>% 
	dplyr::select(id, trait, pmid, author, consortium, category, subcategory, EFO, EFO_id, match, sample_size, ncase, ncontrol, unit, sd) 

save(nodes, file="../results/01/nodes.rdata")
