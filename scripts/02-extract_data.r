library(tidyverse)
library(TwoSampleMR)

try_extract_instrument <- function(id, pval, tries=3)
{
	i <- 1
	out <- 1
	class(out) <- 'try-error'
	while(class(out) == 'try-error' & i <= tries)
	{
		message("trying iteration ", i)
		out <- try(extract_instruments(id, pval))
		i <- i + 1
	}
	return(out)
}

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

ds <- commandArgs(T)[1]

load(paste0("../data/results/", ds, "/nodes.rdata"))

l <- list()
m <- list()
j <- 1
for(i in 1:nrow(nodes))
{
	temp <- try_extract_instrument(nodes$id[i])
	if(!class(temp) == 'try-error' & !is.null(temp))
	{
		temp$id.exposure <- nodes$id[i]
		l[[i]] <- filter(temp, mr_keep.exposure) %>%
			select(id.exposure, SNP, effect_allele.exposure, other_allele.exposure, eaf.exposure, beta.exposure, se.exposure, pval.exposure, samplesize.exposure, ncase.exposure, ncontrol.exposure)
		temp <- try_extract_outcome(temp$SNP, nodes$id)
		m[[i]] <- filter(temp, mr_keep.outcome) %>%
			select(id.outcome, SNP, effect_allele.outcome, other_allele.outcome, eaf.outcome, beta.outcome, se.outcome, pval.outcome, samplesize.outcome, ncase.outcome, ncontrol.outcome, proxy.outcome, proxy_snp.outcome)
	}
}

exposure_datl <- l
outcome_datl <- m
save(exposure_datl, outcome_datl, file=paste0("../data/results/", ds, "/extract.rdata"))

