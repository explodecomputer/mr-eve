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
parser$add_argument('--newidlist', required=FALSE)
parser$add_argument('--gwasdir', required=TRUE)
parser$add_argument('--id', required=TRUE)
parser$add_argument('--rf', required=TRUE)
parser$add_argument('--what', default="eve")
parser$add_argument('--out', required=TRUE)
parser$add_argument('--threads', type="integer", default=1)
parser$add_argument('--idinfo', default="idinfo.rdata")
args <- parser$parse_args()
str(args)

# Check file exists for ID
id <- args[["id"]]
filename <- file.path(args[["gwasdir"]],id,"derived/instruments/ml.csv.gz")
stopifnot(file.exists(filename))

# Read in ID lists
idlist <- scan(args[["idlist"]], what=character())
if(!is.null(args[["newidlist"]]))
{
	newidlist <- scan(args[["newidlist"]], what=character())
} else {
	newidlist <- NULL
}

# Load stuff
load(args[["idinfo"]])
load(args[["rf"]])

# Determine analyses to run
param <- mreve::determine_analyses(id, idlist, newidlist, args[["what"]])

a <- try(mreve::readml(filename, idinfo))
if(nrow(a$exposure_dat) == 0)
{
	param <- subset(param, exposure != id)
}
if(nrow(param) == 0)
{
	scan <- list()
	param[["available"]] <- logical(0)
	save(scan, param, file=args[["out"]])
	q()
}

scan <- parallel::mclapply(param$id, function(i)
{
	p <- subset(param, id == i)
	res <- try({
		if(p$exposure == id)
		{
			b <- mreve::readml(file.path(args[["gwasdir"]], p$outcome, "derived/instruments/ml.csv.gz"), idinfo)
			dat <- TwoSampleMR::harmonise_data(a$exposure_dat, b$outcome_dat)
		} else {
			b <- mreve::readml(file.path(args[["gwasdir"]], p$exposure, "derived/instruments/ml.csv.gz"), idinfo)
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
