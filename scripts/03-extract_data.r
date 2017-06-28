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

ds <- "02"

load(paste0("../results/", ds, "/nodes.rdata"))
load(paste0("../results/", ds, "/exposure_dat.rdata"))

filt <- function(temp)
{
	temp <- filter(temp, mr_keep.outcome) %>%
                select(id.outcome, SNP, effect_allele.outcome, other_allele.outcome, eaf.outcome, beta.outcome, se.outcome, pval.outcome, samplesize.outcome, ncase.outcome, ncontrol.outcome, proxy.outcome, proxy_snp.outcome)
	return(temp)
}

# load("../results/01/outcome_nodes.rdata")
# load("../results/01/exposure_dat.rdata")

snps <- unique(exposure_dat$SNP)
# for(i in 1:nrow(nodes))
for(i in 32)
{
	j <- nodes$id[i]
	message(i," of ", nrow(outcome_nodes), ": ", j)
	snpsneed <- snps
	out <- paste0("../data/results/02/interim/interim-", j, ".rdata")
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

