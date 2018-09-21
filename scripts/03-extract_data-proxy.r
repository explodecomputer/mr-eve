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
		out <- try(extract_outcome_data(SNP, id, proxies=TRUE, splitsize=5000))
		i <- i + 1
	}
	return(out)
}

###

ds <- "03"

load(paste0("../results/", ds, "/nodes.rdata"))
load(paste0("../results/", ds, "/exposure_dat.rdata"))

filt <- function(temp)
{
	temp <- filter(temp, mr_keep.outcome) %>%
                select(id.outcome, SNP, effect_allele.outcome, other_allele.outcome, eaf.outcome, beta.outcome, se.outcome, pval.outcome, samplesize.outcome, ncase.outcome, ncontrol.outcome, proxy.outcome, proxy_snp.outcome)
	return(temp)
}

snps <- unique(exposure_dat$SNP)
snpdat <- data_frame(SNP=snps)

for(i in 1:nrow(nodes))
{
	j <- nodes$id[i]
	message(i," of ", nrow(nodes), ": ", j)
	snpsneed <- snps
	out <- paste0("../results/03/extract/outcome-", j, ".rdata")
	if(file.exists(out))
	{
		message("Loading previous version")
		load(out)
		snpsgot <- unique(temp$SNP)
		snpsneed <- snps[!snps %in% snpsgot]
		temp2 <- try_extract_outcome(snpsneed, nodes$id[i])
		temp2 <- filt(temp2)
		temp <- rbind(temp, temp2)
	} else {
		message("No previous record")
		temp <- try_extract_outcome(snps, nodes$id[i])
		temp <- filter(temp, mr_keep.outcome) %>%
			select(id.outcome, SNP, effect_allele.outcome, other_allele.outcome, eaf.outcome, beta.outcome, se.outcome, pval.outcome, samplesize.outcome, ncase.outcome, ncontrol.outcome)
		outcome_dat <- merge(temp, snpdat, by="SNP", all=TRUE)
		outcome_dat$id.outcome <- nodes$id[i]
	}
	save(outcome_dat, file=out)
}

