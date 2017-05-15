library(tidyverse)

ao <- read_csv("../data/ao.csv")
keep <- subset(ao, !is.na(EFO)) %>% 
	select(id, trait, pmid, author, consortium, category, subcategory, EFO, EFO_id, match, sample_size, ncase, ncontrol, unit, sd) 

nodes <- keep[sample(1:nrow(keep), 3, replace=FALSE), ]
save(nodes, file="../results/01/nodes.rdata")
