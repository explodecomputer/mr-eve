library(tidyverse)
library(data.table)

ao <- read_csv("../data/ao.csv")
ids <- scan("../results/02/ids.txt")

outcome_nodes <- subset(ao, 
	id %in% ids |
	author == "Shin" |
	author == "Kettunen"
	) %>% 
	dplyr::select(id, trait, pmid, author, consortium, category, subcategory, EFO, EFO_id, match, sample_size, ncase, ncontrol, unit, sd) 
outcome_nodes$id <- as.character(outcome_nodes$id)


som <- read_tsv("../data/soma.txt")
som$sample_size <- 3301
som$author <- "Sun"
som$category <- "SOMA"
som$sd <- 1
som$unit <- "SD"

soma_nodes <- filter(som, !duplicated(`SOMAmer ID`)) %>%
	dplyr::select(
		id=`SOMAmer ID`, 
		trait=Target,
		sample_size,
		author,
		category,
		unit,
		sd
	)


# a <- fread("../data/2012-12-21-CisAssociationsProbeLevelFDR0.5.txt")
# westra_nodes <- filter(a, !duplicated(ProbeName) & PValue < 5e-5)


# b <- filter(a, PValue < 5e-5 & !duplicated()) %>%
# 	arrange(PValue) %>%
# 	filter(!duplicated(ProbeName))
# fr <- fread("westrasnps.txt.frq")



nodes <- bind_rows(outcome_nodes, soma_nodes)


save(nodes, file="../results/02/nodes.rdata")
