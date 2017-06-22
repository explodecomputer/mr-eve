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
		out <- try(extract_outcome_data(SNP, id, proxies=FALSE))
		i <- i + 1
	}
	return(out)
}

###

ds <- "01"

load(paste0("../results/", ds, "/outcome_nodes.rdata"))
load(paste0("../results/", ds, "/exposure_dat.rdata"))

filt <- function(temp)
{
	temp <- filter(temp, mr_keep.outcome) %>%
                select(id.outcome, SNP, effect_allele.outcome, other_allele.outcome, eaf.outcome, beta.outcome, se.outcome, pval.outcome, samplesize.outcome, ncase.outcome, ncontrol.outcome, proxy.outcome, proxy_snp.outcome)
	return(temp)
}

snps <- unique(exposure_dat$SNP)
for(i in 50)
{
	j <- outcome_nodes$id[i]
	message(i," of ", nrow(outcome_nodes), ": ", j)
	snpsneed <- snps
	out <- paste0("../data/results/01/interim-", j, ".rdata")
	if(file.exists(out))
	{
		message("Loading previous version")
		load(out)
		snpsgot <- unique(temp$SNP)
		snpsneed <- snps[!snps %in% snpsgot]
		temp2 <- try_extract_outcome(snpsneed, outcome_nodes$id[i])
		temp2 <- filt(temp2)
		temp <- rbind(temp, temp2)
	} else {
		message("No previous record")
		temp <- try_extract_outcome(snps, outcome_nodes$id[i])
		temp <- filter(temp, mr_keep.outcome) %>%
			select(id.outcome, SNP, effect_allele.outcome, other_allele.outcome, eaf.outcome, beta.outcome, se.outcome, pval.outcome, samplesize.outcome, ncase.outcome, ncontrol.outcome)
	}
	save(temp, file=out)
}


