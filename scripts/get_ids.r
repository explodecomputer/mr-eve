library(TwoSampleMR)
library(dplyr)
ao <- available_outcomes()
idlist <- filter(ao, 
	access %in% c("immunobase_users", "public", "Public"),
	nsnp > 100000,
	mr
) %>% mutate(file=file.path("../gwas-files", id, "data.bcf")) %>%
filter(file.exists(file)) %>% as_tibble()


write.table(idlist$id, file="data/idlist.txt", row=FALSE, col=FALSE, qu=FALSE)
save(idlist, file="data/idlist.rdata")

