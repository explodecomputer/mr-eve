
library(TwoSampleMR)
library(dplyr)
library(data.table)

ids <- scan("../ids.txt", what="character")

ao <- available_outcomes()
ao <- suppressMessages(available_outcomes())

ao2 <- subset(ao, id %in% ids) %>% filter(!author %in% c("Shin", "Kettunen", "Roederer", "Neale")) 

all_ids <- ao2$id
disease_ids <- subset(ao2, category=="Disease")$id

b <- fread("trait_trait_sel.csv")

b1 <- subset(b, `:START_ID(trait)` %in% ao2$id & `:END_ID(trait)` %in% ao2$id & `P:FLOAT` < 0.001)
b1 <- subset(b1, ! `:START_ID(trait)` %in% disease_ids)

names(b1) <- c("method", "b", "se", "ci_lo", "ci_up", "pval", "nsnp", "exposure", "outcome", "moe_prob")

save(ao2, b1, file="network.rdata")


