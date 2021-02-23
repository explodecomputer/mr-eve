library(mrever)
library(tidyverse)
library(jsonlite)

config <- read_json("config.json")

args <- commandArgs(T)
id <- args[1]
headerid <- args[2]
message(id)

mrpath <- file.path(config$outdir, "data", id, "mr.rdata")
stopifnot(file.exists(mrpath))
hetpath <- file.path(config$outdir, "data", id, "heterogeneity.rdata")
stopifnot(file.exists(hetpath))

dir.create(file.path(config$outdir, "data", id, "neo4j_stage"))
mrout <- file.path(config$outdir, "data", id, "neo4j_stage", paste0(id, "_mr.csv.gz"))
hetout <- file.path(config$outdir, "data", id, "neo4j_stage", paste0(id, "_het.csv.gz"))
moeout <- file.path(config$outdir, "data", id, "neo4j_stage", paste0(id, "_moe.csv.gz"))
intout <- file.path(config$outdir, "data", id, "neo4j_stage", paste0(id, "_int.csv.gz"))
metout <- file.path(config$outdir, "data", id, "neo4j_stage", paste0(id, "_met.csv.gz"))
vtout <- file.path(config$outdir, "data", id, "neo4j_stage", paste0(id, "_vt.csv.gz"))
instout <- file.path(config$outdir, "data", id, "neo4j_stage", paste0(id, "_inst.csv.gz"))

##

load(mrpath)
estimates <- lapply(scan, function(x) {
	if(is.null(x$estimates)) return(NULL)
	estimates <- x$estimates
	if("MOE" %in% names(estimates))
	{
		estimates <- dplyr::select(estimates, -c(method2, steiger_filtered, outlier_filtered))
	} else {
		estimates$selection <- "Tophits"
		estimates$selection[estimates$steiger_filtered & estimates$outlier_filtered] <- "DF + HF"
		estimates$selection[!estimates$steiger_filtered & estimates$outlier_filtered] <- "HF"
		estimates$selection[estimates$steiger_filtered & !estimates$outlier_filtered] <- "DF"
		estimates <- estimates %>% dplyr::select(-c(steiger_filtered, outlier_filtered))
		estimates$MOE <- 0
		ind <- estimates$method %in% c("Wald ratio", "FE IVW", "Steiger null") & estimates$selection == "DF"
		estimates$MOE[ind] <- 1
		ind <- is.infinite(estimates$b)
		estimates$b[ind] <- 0
		estimates$se[ind] <- NA
		estimates$ci_low[ind] <- NA
		estimates$ci_upp[ind] <- NA
		estimates$pval[ind] <- 1
	}
	estimates
}) %>% bind_rows

write_empty <- function(fn)
{
	con <- gzfile(fn, "w")
	writeLines("", con)
	close(con)	
}

if(nrow(estimates) == 0)
{
	write_empty(mrout)
	write_empty(moeout)
	write_empty(intout)
	write_empty(hetout)
	write_empty(metout)
	write_empty(vtout)
	write_empty(instout)
	q()
}

names(estimates)[names(estimates) == "MOE"] <- "moescore"
mr <- estimates
write_simple(mr, mrout, "id.exposure", "ogid", "id.outcome", "ogid", col.names=FALSE)

mrmoe <- estimates %>%
	group_by(id.exposure, id.outcome) %>% 
	filter(moescore == max(moescore)) %>% 
	dplyr::slice(1)
write_simple(mrmoe, moeout, "id.exposure", "ogid", "id.outcome", "ogid", col.names=FALSE)


intercept <- lapply(scan, function(x) x$directional_pleiotropy) %>% 
	bind_rows()
if(nrow(intercept) > 0)
{
	intercept$selection <- "Tophits"
	intercept$selection[intercept$steiger_filtered & intercept$outlier_filtered] <- "DF + HF"
	intercept$selection[!intercept$steiger_filtered & intercept$outlier_filtered] <- "HF"
	intercept$selection[intercept$steiger_filtered & !intercept$outlier_filtered] <- "DF"
	intercept <- intercept %>% dplyr::select(-c(steiger_filtered, outlier_filtered))
	write_simple(intercept, intout, "id.exposure", "ogid", "id.outcome", "ogid", col.names=FALSE)
} else {
	write_empty(intout)
}

expected_columns <- c("id.exposure", "id.outcome", "nsnp", "nout", "nexp", "meanF", "varF", "medianF", "egger_isq", "sct", "Isq", "Isqe", "Qdiff", "intercept", "dfb1_ivw", "dfb2_ivw", "dfb3_ivw", "cooks_ivw", "dfb1_egger", "dfb2_egger", "dfb3_egger", "cooks_egger", "homosc_ivw", "homosc_egg", "shap_ivw", "shap_egger", "ks_ivw", "ks_egger", "nsnp_removed", "selection")

met <- lapply(scan, function(x) x$info) %>% 
	bind_rows()
if(nrow(met) > 0)
{
	met$selection <- "Tophits"
	met$selection[met$steiger_filtered & met$outlier_filtered] <- "DF + HF"
	met$selection[!met$steiger_filtered & met$outlier_filtered] <- "HF"
	met$selection[met$steiger_filtered & !met$outlier_filtered] <- "DF"
	met <- met %>% dplyr::select(-c(steiger_filtered, outlier_filtered))
	if(!all(expected_columns %in% names(met)))
	{
		temp <- as.list(rep(NA, length(expected_columns)))
		names(temp) <- expected_columns
		temp <- l %>% dplyr::bind_cols()
		met <- dplyr::bind_rows(temp, met) %>% dplyr::slice(-1)
	}
	write_simple(met, metout, "id.exposure", "ogid", "id.outcome", "ogid", col.names=FALSE)
} else {
	write_empty(metout)
}

het <- lapply(scan, function(x) x$heterogeneity) %>% 
	bind_rows()
if(nrow(het) > 0)
{
	het$selection <- "Tophits"
	het$selection[het$steiger_filtered & het$outlier_filtered] <- "DF + HF"
	het$selection[!het$steiger_filtered & het$outlier_filtered] <- "HF"
	het$selection[het$steiger_filtered & !het$outlier_filtered] <- "DF"
	het <- het %>% dplyr::select(-c(steiger_filtered, outlier_filtered))
	names(het)[names(het) == "Q"] <- "q"
	write_simple(het, hetout, "id.exposure", "ogid", "id.outcome", "ogid", col.names=FALSE)
} else {
	write_empty(hetout)
}


##

# - variant-Trait

rsid <- scan(file.path(config$outdir, "resources", "instruments.txt"), what=character())

load(file.path(config$outdir, "resources", "ids.txt.rdata"))
idinfo <- idinfo %>% dplyr:: select(-c(mr, file))

vtpath <- file.path(config$outdir, "data", id, "ml.csv.gz")
stopifnot(file.exists(vtpath))

a <- readml(vtpath, idinfo, format="none")
a <- subset(a, SNP %in% rsid)
a$ogid <- id
vt <- subset(a, select=c(SNP, ogid, beta, se, pval, eaf, samplesize, ncase, ncontrol))
vtinst <- subset(vt, a$instrument)
vt$proxy <- a$proxy_rsid != ""

write_simple(vt, vtout, "SNP", "variant", "ogid", "ogid", col.names=FALSE)
write_simple(vtinst, instout, "SNP", "variant", "ogid", "ogid", col.names=FALSE)

fn <- function(nom)
{
	file.path(config$outdir, "resources", "neo4j_stage", paste0("header_", nom, ".csv.gz"))
}

if(id == headerid)
{
	message("writing header files")
	write_simple(het, fn("het"), "id.exposure", "ogid", "id.outcome", "ogid", headeronly=TRUE)
	write_simple(intercept, fn("int"), "id.exposure", "ogid", "id.outcome", "ogid", headeronly=TRUE)
	write_simple(mrmoe, fn("moe"), "id.exposure", "ogid", "id.outcome", "ogid", headeronly=TRUE)
	write_simple(met, fn("met"), "id.exposure", "ogid", "id.outcome", "ogid", headeronly=TRUE)
	write_simple(mr, fn("mr"), "id.exposure", "ogid", "id.outcome", "ogid", headeronly=TRUE)
	write_simple(vt, fn("vt"), "SNP", "variant", "ogid", "ogid", headeronly=TRUE)
	write_simple(vtinst, fn("inst"), "SNP", "variant", "ogid", "ogid", headeronly=TRUE)
}

