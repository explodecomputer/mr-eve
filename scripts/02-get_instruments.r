# Get exposure SNPs

## Kettunen metabolites

library(tidyverse)
library(TwoSampleMR)
library(MRInstruments)

## Soma scan proteins

som <- read_tsv("../data/soma.txt")
som$samplesize <- 3301

soma <- format_data(
	som,
	snp_col = "Sentinel variant*",
	effect_allele_col = "Effect Allele (EA)",
	other_allele_col = "Other Allele (OA)",
	eaf_col = "EAF",
	phenotype_col = "Target fullname",
	beta_col = "beta_overall",
	se_col = "SE_overall",
	pval_col = "p_overall",
	samplesize_col = "samplesize"
)


load("../results/02/nodes.rdata")

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

nodes$type <- NA
ao <- available_outcomes()

l <- list()
for(i in 1:nrow(nodes))
{
	message(i)
	if(nodes$id[i] %in% ao$id)
	{	
		temp <- try_extract_instrument(nodes$id[i], 5e-8)
		if(!class(temp) == 'try-error' & !is.null(temp))
		{
			temp$id.exposure <- nodes$id[i]
			temp$exposure <- nodes$trait[i]
			nodes$type[i] <- "eo"
			l[[i]] <- filter(temp, mr_keep.exposure) %>%
				select(id.exposure, SNP, effect_allele.exposure, other_allele.exposure, eaf.exposure, beta.exposure, se.exposure, pval.exposure, samplesize.exposure, ncase.exposure, ncontrol.exposure)
		} else {
			nodes$type[i] <- "o"
		}
	} else {
		nodes$type[i] <- "e"
	}
}

e <- bind_rows(l)
exposure_dat <- plyr::rbind.fill(e, soma)
exposure_dat <- subset(exposure_dat, pval.exposure < 5e-8 & mr_keep.exposure)

save(nodes, file="../results/02/nodes.rdata")
save(exposure_dat, file="../results/02/exposure_dat.rdata")

