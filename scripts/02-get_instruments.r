# Get exposure SNPs

## Kettunen metabolites

library(tidyverse)
library(TwoSampleMR)
library(MRInstruments)
data(metab_qtls)

metab_qtls <- format_metab_qtls(metab_qtls)


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


## Extract Shin QTLs

shin <- read_csv("../data/shin_metab.csv")
shin <- shin %>% separate("Effect (SE)", c("beta", "se"), sep=" \\(")
shin$se <- gsub(")", "", shin$se) %>% as.numeric
shin$beta <- as.numeric(shin$beta)
shin <- shin %>% separate("EA/OA1", c("ea", "nea"), sep="/")

shin <- format_data(
	shin,
	snp_col = "SNP",
	effect_allele_col = "ea",
	other_allele_col = "nea",
	eaf_col = "EAF2",
	phenotype_col = "Biochemical(s)",
	beta_col = "beta",
	se_col = "se",
	pval_col = "P-value",
	samplesize_col = "N"
)


load("../results/01/outcome_nodes.rdata")

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


l <- list()
for(i in 1:nrow(nodes))
{
	temp <- try_extract_instrument(nodes$id[i])
	if(!class(temp) == 'try-error' & !is.null(temp))
	{
		temp$id.exposure <- nodes$id[i]
		l[[i]] <- filter(temp, mr_keep.exposure) %>%
			select(id.exposure, SNP, effect_allele.exposure, other_allele.exposure, eaf.exposure, beta.exposure, se.exposure, pval.exposure, samplesize.exposure, ncase.exposure, ncontrol.exposure)
	}
}

e <- bind_rows(l)
exposure_dat <- plyr::rbind.fill(e, shin, soma, metab_qtls)
exposure_dat <- subset(exposure_dat, pval.exposure < 5e-8 & mr_keep.exposure)

save(exposure_dat, file="../results/01/exposure_dat.rdata")



