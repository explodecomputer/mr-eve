# Make trait, snp and gene nodes
library(mreve)
library(tidyverse)
library(data.table)
library(GenomicRanges)


## Nodes

# read instrument list
variants <- fread("resources/instruments.txt", header=FALSE) %>% as_tibble()
names(variants) <- c("chr", "pos", "ref", "alt", "build", "rsid")
variants$chr <- as.character(variants$chr)
variantsfile <- write_simple(variants, "resources/neo4j_stage/variants.csv.gz", "rsid", "variant")


# Traits
load("resources/idinfo.rdata")
idinfo <- idinfo %>% dplyr:: select(-c(access, mr, file, filename, path))
traitsfile <- write_simple(idinfo, "resources/neo4j_stage/traits.csv.gz", "id", "bgcid")



# Genes
load("resources/genes.rdata")
genesgr <- subset(genesgr, !duplicated(ensembl_gene_id)) %>% as_tibble()
names(genesgr)[1] <- "chr"
genesgr$chr <- as.character(genesgr$chr)
genesfile <- write_simple(genesgr, "resources/neo4j_stage/genes.csv.gz", "ensembl_gene_id", "ensembl_gene_id")




## Relationships


# - Variant-Gene
# Add 500kb region around each gene
load("resources/genes.rdata")
genesgr <- subset(genesgr, !duplicated(ensembl_gene_id)) %>% as_tibble()
genesgr$origstart <- genesgr$start
genesgr$start <- pmax(0, genesgr$start - 500000)
genesgr$end <- genesgr$end + 500000
genesgr$width <- genesgr$end - genesgr$start + 1
genesgr <- GRanges(genesgr)
vars <- GRanges(variants$chr, IRanges(start=variants$pos, end=variants$pos), rsid = variants$rsid)
a <- findOverlaps(vars, genesgr) %>% as_tibble
b <- bind_cols(vars[a$queryHits,] %>% as_tibble(), genesgr[a$subjectHits,] %>% as_tibble())
b$tss_dist <- abs(b$start - b$origstart)
gv <- tibble(ensembl_gene_id = b$ensembl_gene_id, variant = b$rsid, tss_dist = b$tss_dist)

gvfile <- write_simple(gv, "resources/neo4j_stage/gv.csv.gz", "ensembl_gene_id", "ensembl_gene_id", "variant", "variant")


# - variant-Trait
vt <- list()
vtinst <- list()
for(i in 1:nrow(idinfo))
{
	x <- idinfo$id[i]
	message(x, " - ", i, " of ", nrow(idinfo))
	a <- readml(file.path("../gwas-files", x, "derived/instruments/ml.csv.gz"), idinfo, format="none")
	a$bgcid <- x
	vt[[i]] <- subset(a, select=c(SNP, bgcid, beta, se, pval, eaf, samplesize, ncase, ncontrol))
	vtinst[[i]] <- subset(vt[[i]], a$instrument)
	vt[[i]]$proxy <- !is.na(a$proxy_chr)
}

vtfiles <- write_split(vt, 200, "resources/neo4j_stage/vt", "SNP", "variant", "bgcid", "bgcid")
vtinst <- bind_rows(vtinst)
vtinstfile <- write_split("resources/neo4j_stage/instruments.csv.gz", "SNP", "variant", "bgcid", "bgcid")


# mr
# mrmoe
# mrhet
# mrintercept
# metrics

mr <- list()
mrmoe <- list()
mrhet <- list()
mrintercept <- list()
metrics <- list()
for(i in 1:nrow(idinfo))
{
	x <- idinfo$id[i]
	message(x, " - ", i, " of ", nrow(idinfo))
	load(file.path("../gwas-files", x, "derived/instruments/mr.rdata"))

	estimates <- lapply(scan, function(x) x$estimates) %>% bind_rows

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
	}
	names(estimates)[names(estimates) == "MOE"] <- "moescore"
	mr[[i]] <- estimates

	mrmoe[[i]] <- group_by(estimates, id.exposure, id.outcome) %>% 
	filter(moescore == max(moescore)) %>% dplyr::slice(1)

	het <- lapply(scan, function(x) x$heterogeneity) %>% bind_rows
	het$selection <- "Tophits"
	het$selection[het$steiger_filtered & het$outlier_filtered] <- "DF + HF"
	het$selection[!het$steiger_filtered & het$outlier_filtered] <- "HF"
	het$selection[het$steiger_filtered & !het$outlier_filtered] <- "DF"
	het <- het %>% dplyr::select(-c(steiger_filtered, outlier_filtered))
	names(het)[names(het) == "Q"] <- "q"
	mrhet[[i]] <- het

	intercept <- lapply(scan, function(x) x$directional_pleiotropy) %>% bind_rows
	intercept$selection <- "Tophits"
	intercept$selection[intercept$steiger_filtered & intercept$outlier_filtered] <- "DF + HF"
	intercept$selection[!intercept$steiger_filtered & intercept$outlier_filtered] <- "HF"
	intercept$selection[intercept$steiger_filtered & !intercept$outlier_filtered] <- "DF"
	intercept <- intercept %>% dplyr::select(-c(steiger_filtered, outlier_filtered))
	mrintercept[[i]] <- intercept

	met <- lapply(scan, function(x) x$info) %>% bind_rows
	met$selection <- "Tophits"
	met$selection[met$steiger_filtered & met$outlier_filtered] <- "DF + HF"
	met$selection[!met$steiger_filtered & met$outlier_filtered] <- "HF"
	met$selection[met$steiger_filtered & !met$outlier_filtered] <- "DF"
	met <- met %>% dplyr::select(-c(steiger_filtered, outlier_filtered))
	metrics[[i]] <- met
}

mrfiles <- write_split(mr, 200, "resources/neo4j_stage/mr", "id.exposure", "bgcid", "id.outcome", "bgcid")
mrhetfiles <- write_split(mrhet, 200, "resources/neo4j_stage/mrhet", "id.exposure", "bgcid", "id.outcome", "bgcid")
mrinterceptfiles <- write_split(mrintercept, 200, "resources/neo4j_stage/mrintercept", "id.exposure", "bgcid", "id.outcome", "bgcid")
mrmoefiles <- write_split(mrmoe, 200, "resources/neo4j_stage/mrmoe", "id.exposure", "bgcid", "id.outcome", "bgcid")
metricsfiles <- write_split(metrics, 200, "resources/neo4j_stage/metrics", "id.exposure", "bgcid", "id.outcome", "bgcid")




cmd <- paste0(
"~/neo4j-community-3.2.0/bin/neo4j-admin import", 
" --database mr-eve.db", 
" --id-type string", 
" --nodes:GENE ", genesfile, 
" --nodes:VARIANT ", variantsfile, 
" --nodes:TRAIT ", traitsfile, 
" --relationships:ANNOTATION ", gvfile, 
" --relationships:INSTRUMENT ", vtinstfile, 
" --relationships:GENASSOC ", vtfiles, 
" --relationships:MR ", mrfiles, 
" --relationships:MRMOE ", mrmoefiles,
" --relationships:MRINTERCEPT ", mrinterceptfiles,
" --relationships:MRHET ", mrhetfiles,
" --relationships:METRICS ", metricsfiles
)

# system(cmd)

