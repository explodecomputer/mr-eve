Sys.setenv(TZ = "America/Toronto")

suppressWarnings(suppressPackageStartupMessages({
	library(TwoSampleMR)
	library(mreve)
	library(tidyverse)
	library(car)
	library(randomForest)
	library(parallel)
	library(argparse)
}))



# create parser object
parser <- ArgumentParser()
parser$add_argument('--idlist', required=TRUE)
parser$add_argument('--gwasdir', required=TRUE)
parser$add_argument('--id', required=TRUE)
parser$add_argument('--rf', required=TRUE)
parser$add_argument('--what', default="phewas")
parser$add_argument('--out', required=TRUE)
parser$add_argument('--threads', type="integer", default=1)
parser$add_argument('--ao', default="ao.rdata")
args <- parser$parse_args()

idlist <- scan(args[["idlist"]], what=character())
id <- args[["id"]]
stopifnot(id %in% idlist)
idlist <- idlist[!idlist %in% id]
filename <- file.path(args[["gwasdir"]],id,"derived/instruments/ml.csv.gz")
stopifnot(file.exists(filename))
load(args[["ao"]])
load(args[["rf"]])
# Determine analyses to run
if(args[["what"]] == "phewas")
{
	# Bidirectional
	param <- bind_rows(
		tibble(exposure=id, outcome=idlist),
		tibble(exposure=idlist, outcome=id)
	)
} else if(args[["what"]] == "exposure") {
	# Just id as exposure
	param <- tibble(exposure=id, outcome=idlist)
} else if(args[["what"]] == "exposure") {
	# Just id as outcome
	param <- tibble(exposure=idlist, outcome=id)
} else if(args[["what"]] == "triangle") {
	# Avoid duplicate computation by only taking lower triangle
	param <- bind_rows(
		tibble(exposure=id, outcome=idlist),
		tibble(exposure=idlist, outcome=id)
	)
	param <- subset(param, exposure != outcome)
	param <- subset(param, !duplicated(paste(exposure, outcome)))
	param <- param[apply(param, 1, function(x) order(c(x[1], x[2]))[1] == 1), ] %>% arrange(exposure, outcome)	
}
	
param$id <- paste0(param$exposure, ".", param$outcome)
a <- try(mreve::readml(filename, ao))
if(nrow(a$exposure_dat) == 0)
{
	param <- subset(param, exposure != id)
}
scan <- parallel::mclapply(param$id, function(i)
{
	p <- subset(param, id == i)
	res <- try({
		if(p$exposure == id)
		{
			b <- mreve::readml(file.path(args[["gwasdir"]], p$outcome, "derived/instruments/ml.csv.gz"), ao)
			dat <- TwoSampleMR::harmonise_data(a$exposure_dat, b$outcome_dat)
		} else {
			b <- mreve::readml(file.path(args[["gwasdir"]], p$exposure, "derived/instruments/ml.csv.gz"), ao)
			dat <- TwoSampleMR::harmonise_data(b$exposure_dat, a$outcome_dat)
		}
		res <- TwoSampleMR::mr_wrapper(dat)
		res <- TwoSampleMR::mr_moe(res, rf)
		rm(b,dat)
		res
	})
	if(class(res) == "try-error") return(NULL)
	return(res[[1]])
}, mc.cores=args[["threads"]])
names(scan) <- param$id
param$available <- TRUE
param$available[sapply(scan, is.null)] <- FALSE

save(scan, param, file=args[["out"]])
