suppressWarnings(suppressPackageStartupMessages({
	library(TwoSampleMR)
	library(mrever)
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
parser$add_argument('--outdir', required=TRUE)
parser$add_argument('--id', required=TRUE)
parser$add_argument('--rf', required=TRUE)
parser$add_argument('--what', default="eve")
parser$add_argument('--threads', type="integer", default=1)
args <- parser$parse_args()
str(args)

# Check file exists for ID
id <- args[["id"]]
filename <- file.path(args[["outdir"]], "data", id, "ml.csv.gz")
stopifnot(file.exists(filename))

message("reading id lists")

# Read in ID lists
load(args[["idlist"]])
if(!is.null(args[["newidlist"]]))
{
	newidlist <- scan(args[["newidlist"]], what=character())
} else {
	newidlist <- NULL
}

idlist <- idinfo$id

message(length(idlist), " ids to analyse")

# Load stuff
load(args[["rf"]])

# Determine analyses to run
param <- mrever::determine_analyses(id, idlist, newidlist, args[["what"]])
str(param)

a <- try(mrever::readml(filename, idinfo))
glimpse(a$exposure_dat)
if(nrow(a$exposure_dat) == 0)
{
	message("removing exposure analyses due to no instruments")
	param <- param[param$exposure != id, ]
}
str(param)

if(nrow(param) == 0)
{
	message("No analyses left to run")
	scan <- list()
	param[["available"]] <- logical(0)
	save(scan, param, file=file.path(args[["outdir"]], "data", id, "mr.rdata"))
	q()
}

mr_params <- default_parameters()
mr_params$nboot <- 500

scan <- parallel::mclapply(param$id, function(i)
{
	p <- subset(param, id == i)
	message(p$id)
	res <- try({
		if(p$exposure == id)
		{
			b <- mrever::readml(file.path(args[["outdir"]], "data", p$outcome, "ml.csv.gz"), idinfo)
			dat <- suppressMessages(TwoSampleMR::harmonise_data(a$exposure_dat, b$outcome_dat))
		} else {
			b <- mrever::readml(file.path(args[["outdir"]], "data", p$exposure, "ml.csv.gz"), idinfo)
			dat <- TwoSampleMR::harmonise_data(b$exposure_dat, a$outcome_dat)
		}
		res <- suppressMessages(TwoSampleMR::mr_wrapper(dat, parameters=mr_params))
		res <- suppressMessages(TwoSampleMR::mr_moe(res, rf))
		rm(b,dat)
		res
	})
	if(class(res) == "try-error") return(NULL)
	return(res[[1]])
}, mc.cores=args[["threads"]])
names(scan) <- param$id
param$available <- TRUE
param$available[sapply(scan, is.null)] <- FALSE

save(scan, param, file=file.path(args[["outdir"]], "data", id, "mr.rdata"))
