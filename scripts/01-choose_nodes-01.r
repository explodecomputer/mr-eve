library(tidyverse)

ao <- read_csv("../data/ao.csv")
ids <- scan("../results/01/ids.txt")

outcome_nodes <- subset(ao, 
	id %in% ids |
	author == "Shin" |
	author == "Kettunen"
	) %>% 
	dplyr::select(id, trait, pmid, author, consortium, category, subcategory, EFO, EFO_id, match, sample_size, ncase, ncontrol, unit, sd) 

save(outcome_nodes, file="../results/01/outcome_nodes.rdata")
