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
parser$add_argument('--what', default="eve")
parser$add_argument('--threads', type="integer", default=1)
args <- parser$parse_args()
str(args)


# Check file exists for ID
id <- args[["id"]]
filename <- file.path(args[["outdir"]], "data", id, "ml.csv.gz")
stopifnot(file.exists(filename))

message("obtain and organise MR results")
load(file.path(args[["outdir"]], "data", id, "mr.rdata"))
mrres <- scan
ests <- sapply(scan, function(x)
{
	if("estimates" %in% names(x))
	{
		if("MOE" %in% names(x$estimates))
		{
			return(x$estimates$b[1])
		}
	}
	return(NA)
}) 
ests <- tibble(id=names(ests), b=ests)

if(nrow(ests) == 0)
{
	message("No analyses left to run")
	scan <- list()
	param[["available"]] <- logical(0)
	save(scan, param, file=file.path(args[["outdir"]], "data", id, "heterogeneity.rdata"))
	q()
}

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

# Determine analyses to run
param <- mrever::determine_analyses(id, idlist, newidlist, args[["what"]])
param <- left_join(param, ests, by="id")
str(param)

a <- try(mrever::readml(filename, idinfo))
glimpse(a$exposure_dat)
if(nrow(a$exposure_dat) < 5)
{
	message("removing exposure analyses due to fewer than 5 instruments")
	param <- param[param$exposure != id, ]
}
param <- subset(param, !is.na(b))
str(param)


if(nrow(param) == 0)
{
	message("No analyses left to run")
	scan <- list()
	param[["available"]] <- logical(0)
	save(scan, param, file=file.path(args[["outdir"]], "data", id, "heterogeneity.rdata"))
	q()
}


hetero <- function(dat, b)
{
	dat <- subset(dat, mr_keep)
	stopifnot(nrow(dat) >= 5)
	dat$ratio <- dat$beta.outcome / dat$beta.exposure
	dat$W <- ((dat$se.outcome^2+(b^2*dat$se.exposure^2))/dat$beta.exposure^2)^-1
	dat$Qj <- dat$W * (dat$ratio - b)^2
	dat$Qj_Chi <- pchisq(dat$Qj, 1, lower.tail=FALSE)
	return(
		tibble(
			id.exposure=dat$id.exposure,
			id.outcome=dat$id.outcome,
			rsid=dat$SNP,
			ratio=dat$ratio,
			Qj=dat$Qj,
			Qj_Chi=dat$Qj_Chi
		)
	)
}

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
		res <- suppressMessages(hetero(dat, p$b))
		rm(b,dat)
		res
	})
	if(class(res) == "try-error") return(NULL)
	return(res)
}, mc.cores=args[["threads"]])
names(scan) <- param$id
param$available <- TRUE
param$available[sapply(scan, is.null)] <- FALSE
scan <- bind_rows(scan)
save(scan, param, file=file.path(args[["outdir"]], "data", id, "heterogeneity.rdata"))
