library(TwoSampleMR)
library(tidyverse)

# calculate rsq.outcome and rsq.exposure
# where there is missing data, just assume instrument in correct direction

get_rsq <- function(dat, logor_outcome)
{
	dat$pval.outcome[dat$pval.outcome < 1e-300] <- 1e-300
	if(logor_outcome)
	{
		ind1 <- !is.na(dat$beta.outcome) &
			!is.na(dat$eaf.outcome) &
			!is.na(dat$ncase.outcome) &
			!is.na(dat$ncontrol.outcome)
		dat$rsq.outcome <- 0
		if(sum(ind1) > 0)
		{
			dat$rsq.outcome[ind1] <- get_r_from_lor(
				dat$beta.outcome[ind1],
				dat$eaf.outcome[ind1],
				dat$ncase.outcome[ind1],
				dat$ncontrol.outcome[ind1],
				0.1
			)^2
		}
	} else {
		ind1 <- !is.na(dat$pval.outcome) & !is.na(dat$samplesize.outcome)
		dat$rsq.outcome <- 0
		if(sum(ind1) > 0)
		{		
			dat$rsq.outcome[ind1] <- get_r_from_pn(
				dat$pval.outcome[ind1],
				dat$samplesize.outcome[ind1]
			)
		}
	}
	return(dat)
}

ds <- "01"

load(paste0("../results/", ds, "/outcome_nodes.rdata"))
load(paste0("../results/", ds, "/exposure_dat.rdata"))

exposure_dat$units.exposure[is.na(exposure_dat$units.exposure)] <- "SD"

ind1 <- exposure_dat$units.exposure == "log odds"
ind2 <- ind1 & 
	!is.na(exposure_dat$beta.exposure) &
	!is.na(exposure_dat$eaf.exposure) &
	!is.na(exposure_dat$ncase.exposure) &
	!is.na(exposure_dat$ncontrol.exposure)

exposure_dat$rsq.exposure[ind1] <- 1

exposure_dat$rsq.exposure[ind2] <- get_r_from_lor(
	exposure_dat$beta.exposure[ind2],
	exposure_dat$eaf.exposure[ind2],
	exposure_dat$ncase.exposure[ind2],
	exposure_dat$ncontrol.exposure[ind2],
	0.1
)^2

exposure_dat$pval.exposure[exposure_dat$pval.exposure < 1e-300] <- 1e-300
ind1 <- ! exposure_dat$units.exposure == "log odds"
ind2 <- ind1 &
	!is.na(exposure_dat$pval.exposure) &
	!is.na(exposure_dat$samplesize.exposure)

exposure_dat$rsq.exposure[ind1] <- 1
exposure_dat$rsq.exposure[ind2] <- get_r_from_pn(
	exposure_dat$pval.exposure[ind2], 
	exposure_dat$samplesize.exposure[ind2]
)^2


for(i in 1:nrow(outcome_nodes))
{
	message(i, ": ", outcome_nodes$id[i])
	load(paste0("../data/results/01/interim-", outcome_nodes$id[i], ".rdata"))
	d <- harmonise_data(exposure_dat, temp)
	d <- merge(d, subset(exposure_dat, select=c(id.exposure, SNP, rsq.exposure)), by=c("id.exposure", "SNP"))
	d <- get_rsq(d, outcome_nodes$unit[i] == "log odds")

	sexp <- d$samplesize.exposure
	sexp[is.na(d$samplesize.exposure)] <- 1000000
	sout <- d$samplesize.outcome
	sout[is.na(d$samplesize.outcome)] <- 1000000
	st <- psych::r.test(n = sexp, n2 = sout, r12 = d$rsq.exposure, r34 = d$rsq.outcome)

	d$steiger_dir <- as.logical(sign(st$z))
	d$steiger_pval <- st$p

	save(d, file=paste0("../results/01/dat/dat-", outcome_nodes$id[i], ".rdata"))
}

