library(tidyverse)
library(TwoSampleMR)

#toggle_dev("test")

try_extract_outcome <- function(SNP, id, tries=3)
{
	i <- 1
	out <- 1
	class(out) <- 'try-error'
	while(class(out) == 'try-error' & i <= tries)
	{
		message("trying iteration ", i)
		out <- try(extract_outcome_data(SNP, id))
		i <- i + 1
	}
	return(out)
}

###

ds <- "01"

load(paste0("../results/", ds, "/outcome_nodes.rdata"))
load(paste0("../results/", ds, "/exposure_dat.rdata"))

snps <- unique(exposure_dat$SNP)

m <- list()
for(i in 1:nrow(outcome_nodes))
{
	temp <- try_extract_outcome(snps, outcome_nodes$id[i])
	m[[i]] <- filter(temp, mr_keep.outcome) %>%
		select(id.outcome, SNP, effect_allele.outcome, other_allele.outcome, eaf.outcome, beta.outcome, se.outcome, pval.outcome, samplesize.outcome, ncase.outcome, ncontrol.outcome, proxy.outcome, proxy_snp.outcome)
}

outcome_datl <- m
save(outcome_datl, file=paste0("../data/results/", ds, "/outcome_extract_", sec, ".rdata"))

