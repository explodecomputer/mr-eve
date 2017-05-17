devtools::install_github("MRCIEU/TwoSampleMR@mr_structure")
library(TwoSampleMR)
library(dplyr)
load("extract_data.rdata")

d <- lapply(d, function(x) {
	x <- subset(x, exposure != outcome)
	x$pval.exposure[x$pval.exposure < 1e-300] <- 1e-300
	x$pval.outcome[x$pval.outcome < 1e-300] <- 1e-300
	return(x)
})

ids <- sapply(d, function(x) { return(x$id.outcome) }) %>% unlist %>% unique

a <- read.csv("~/repo/mr-eve/data/ao.csv")
traits <- subset(a, id %in% ids)


steiger_simple <- function(p_exp, p_out, n_exp, n_out)
{
	r_exp <- sqrt(get_r_from_pn(p_exp, n_exp)^2)
	r_out <- sqrt(get_r_from_pn(p_out, n_out)^2)
	rtest <- psych::r.test(n = n_exp, n2 = n_out, r12 = r_exp, r34 = r_out)
	return(list(dir=r_exp > r_out, pval=rtest$p))
}

m1 <- list()
m2 <- list()
param <- default_parameters()
param$nboot <- 100
for(i in 1:length(d))
{
	message(i)
	x <- d[[i]]
	m1[[i]] <- run_mr(x, parameters=param)

	x <- subset(x, units.exposure != "log odds" & units.outcome != "log odds")
	if(nrow(x) > 0)
	{
		temp <- steiger_simple(x$pval.exposure, x$pval.outcome, x$samplesize.exposure, x$samplesize.outcome)
		x <- x[temp[[1]] & temp[[2]] < 0.05, ]
		m2[[i]] <- run_mr(x, parameters=param)
	}
}

save(m1, m2, file="runmr.rdata")

d2 <- lapply(d, function(x)
{
	
	if(nrow(x) > 0) return(x)
	else return(NULL)
})

d2 <- d2[sapply(d2, function(x) !is.null(x))]

d2 <- lapply(d2, function(x) {
	temp <- steiger_simple(x$pval.exposure, x$pval.outcome, x$samplesize.exposure, x$samplesize.outcome)
	x <- x[temp[[1]] & temp[[2]] < 0.05, ]
	return(x)
})

continuous <- subset(traits, unit != "log odds")


