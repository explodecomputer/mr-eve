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
write.csv(modify_node_headers_for_neo4j(variants, "rsid", "variant"), file="resources/neo4j_stage/variants.csv", row.names=FALSE, na="")

# Traits
load("resources/idlist.rdata")
idlist <- idlist %>% dplyr:: select(-c(access, mr, file, filename, path))
write.csv(modify_node_headers_for_neo4j(idlist, "id", "bgcid"), file="resources/neo4j_stage/traits.csv", row.names=FALSE, na="")

# Genes
load("resources/genes.rdata")
genesgr <- subset(genesgr, !duplicated(ensembl_gene_id)) %>% as_tibble()
names(genesgr)[1] <- "chr"
genesgr$chr <- as.character(genesgr$chr)
write.csv(modify_node_headers_for_neo4j(genesgr, "ensembl_gene_id", "ensembl_gene_id"), file="resources/neo4j_stage/genes.csv", row.names=FALSE, na="")


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
vg <- tibble(ensembl_gene_id = b$ensembl_gene_id, variant = b$rsid, tss_dist = b$tss_dist)
write.csv(modify_rel_headers_for_neo4j(vg, "ensembl_gene_id", "ensembl_gene_id", "variant", "variant"), file="resources/neo4j_stage/gene-variant.csv", row.names=FALSE, na="")


# - variant-Trait
vt <- list()
vtinst <- list()
for(i in 1:nrow(idlist))
{
	x <- idlist$id[i]
	message(x, " - ", i, " of ", nrow(idlist))
	a <- readml(file.path("../gwas-files", x, "derived/instruments/ml.csv.gz"), idlist, format="none")
	a$bgcid <- x
	vt[[i]] <- subset(a, select=c(SNP, bgcid, beta, se, pval, eaf, samplesize, ncase, ncontrol))
	vtinst[[i]] <- subset(vt[[i]], a$instrument)
	vt[[i]]$proxy <- !is.na(a$proxy_chr)
}

vt <- bind_rows(vt)
gz1 <- gzfile("resources/neo4j_stage/variant-trait.csv.gz", "w")
write.csv(modify_rel_headers_for_neo4j(vt, "SNP", "variant", "bgcid", "bgcid"), file=gz1, row.names=FALSE, na="")
close(gz1)

vtinst <- bind_rows(vtinst)
write.csv(modify_rel_headers_for_neo4j(vtinst, "SNP", "variant", "bgcid", "bgcid"), file="resources/neo4j_stage/instrument-trait.csv", row.names=FALSE, na="")


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
for(i in 1:nrow(idlist))
{
	x <- idlist$id[i]
	message(x, " - ", i, " of ", nrow(idlist))
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


mrmoe <- bind_rows(mrmoe)
gz1 <- gzfile("resources/neo4j_stage/variant-trait.csv.gz", "w")
write.csv(modify_rel_headers_for_neo4j(vt, "SNP", "variant", "bgcid", "bgcid"), file=gz1, row.names=FALSE, na="")
close(gz1)

mr <- bind_rows(mr)
mrhet <- bind_rows(mrhet)
mrintercept <- bind_rows(mrintercept)
metrics <- bind_rows(metrics)






# - Trait-Trait

load("../results/01/outcome_nodes.rdata")
load("../results/01/exposure_dat.rdata")

exposure_nodes <- subset(exposure_dat, !duplicated(id.exposure))

exposure_nodes <- dplyr::select(exposure_nodes,
	trait=exposure,
	id=id.exposure,
	unit=units.exposure,
	sample_size=samplesize.exposure,
	ncase=ncase.exposure,
	ncontrol=ncontrol.exposure
)

exposure_nodes <- subset(exposure_nodes, ! id %in% outcome_nodes$id)
# ind1 <- exposure_nodes$trait %in% outcome_nodes$trait
# ind <- match(exposure_nodes$trait[ind1], outcome_nodes$trait)
# ind <- ind[!is.na(ind)]
# exposure_nodes$id[ind1] <- outcome_nodes$id[ind]
# exposure_nodes$trait[ind1] == outcome_nodes$trait[ind]
# exposure_nodes$id[ind1] == outcome_nodes$id[ind]

outcome_nodes$id <- as.character(outcome_nodes$id)
nodes <- bind_rows(exposure_nodes, outcome_nodes)


# table(exposure_nodes$id.exposure %in% outcome_nodes$id)
# table(outcome_nodes$id %in% exposure_nodes$id.exposure)

# temp <- subset(exposure_nodes, data_source.exposure == "Shin metabolites")
# table(temp$exposure %in% outcome_nodes$trait)
# subset(temp, ! exposure %in% outcome_nodes$trait)$exposure
# subset(outcome_nodes, ! trait %in% exposure_nodes$exposure)$trait

# a <- subset(outcome_nodes, author == "Shin")$id

# r <- list()
# for(i in 1:length(a))
# {
# 	message(i)
# 	load(paste0("../results/01/mr/m1-", a[i], ".rdata"))
# 	r[[i]] <- which(sapply(m1, function(x) nrow(subset(x$out, P < 1e-3 & round(Estimate, 1) == 1))) != 0)
# }


# b <- subset(exposure_nodes, data_source.exposure == "Shin metabolites")$exposure
# a <- a[! a %in% b]
# b <- b[! b %in% a]

# table(outcome_nodes$author)

# a <- subset(outcome_nodes, author == "Kettunen")$trait
# b <- subset(exposure_nodes, data_source.exposure == "Kettunen metabolites")$exposure
# a <- a[! a %in% b]
# b <- b[! b %in% a]

# table(b %in% a)

# pmatch(toupper(b[1]), toupper(a))


# table(outcome_nodes$trait %in% exposure_dat$exposure)

# load("../results/01/extract.rdata")
# load("../results/01/mr.rdata")




## Traits
names(nodes)[names(nodes) == "trait"] <- "name"
nodes_out <- modify_node_headers_for_neo4j(nodes, "id", "trait")
write.csv(nodes_out, file="../results/01/upload/traits.csv", row.names=FALSE, na="")


## SNPs and genes
# snp_trait <- exposure_dat %>% filter(!duplicated(SNP))
snp_trait <- exposure_dat

snps <- ucsc_get_position(unique(snp_trait$SNP))
snps <- subset(snps, !duplicated(name)) %>% 
	dplyr::select(name=name, chr=chrom, pos=chromStart, ucsc_func=func) %>% as_data_frame
snps <- bind_rows(snps, data.frame(name=unique(subset(snp_trait, !SNP %in% snps$name)$SNP)))
snps$id <- snps$name
snp_trait <- left_join(snp_trait, dplyr::select(snps, SNP=name, snp_id=id), by="SNP")


gene_snp <- get_gene(subset(snps, !is.na(chr)), "chr", "pos")
gene <- subset(gene_snp, !duplicated(gene_id) & !is.na(gene_id)) %>%
	dplyr::select(chr=gr.seqnames, name=symbol, id=gene_id)


snps <- modify_node_headers_for_neo4j(snps, "id", "snp")
write.csv(snps, file="../results/01/upload/snps.csv", row.names=FALSE, na="")


gene <- modify_node_headers_for_neo4j(gene, "id", "gene")
write.csv(gene, file="../results/01/upload/genes.csv", row.names=FALSE, na="")


## SNP-Gene

gene_snp <- dplyr::select(gene_snp, gene_id, id) %>%
	filter(!is.na(gene_id)) %>% filter(!is.na(id))

gene_snp <- modify_rel_headers_for_neo4j(gene_snp, "gene_id", "gene", "id", "snp")
write.csv(gene_snp, file="../results/01/upload/gene_snp.csv", row.names=FALSE, na="")


## SNP-trait
snp_trait <- subset(snp_trait, select=-c(mr_keep.exposure, exposure, SNP))
names(snp_trait) <- gsub(".exposure", "", names(snp_trait))
snp_trait <- modify_rel_headers_for_neo4j(snp_trait, "snp_id", "snp", "id", "trait")
write.csv(snp_trait, file="../results/01/upload/snp_trait.csv", row.names=FALSE, na="")

## trait-trait

ntt <- 8

for(i in 1:4)
{
	message(i)
	load(paste0("../results/01/mr/mc-", i, ".rdata"))

	m <- bind_rows(a$m)
	m <- modify_rel_headers_for_neo4j(m, "id.exposure", "trait", "id.outcome", "trait")
	write.csv(m, paste0("../results/01/upload/trait_trait-", i, ".csv"), row.names=FALSE, na="", col.names=i == 1)

	mb <- bind_rows(a$mb)
	mb <- modify_rel_headers_for_neo4j(mb, "id.exposure", "trait", "id.outcome", "trait")
	write.csv(mb, paste0("../results/01/upload/trait_trait_sel-", i, ".csv"), row.names=FALSE, na="", col.names=i == 1)

	# so <- bind_rows(a$so)
	# names(so) <- c("SNP", "beta", "se", "pval", "samplesize", "effect_allele", "other_allele", "id")
	# so <- modify_rel_headers_for_neo4j(so, "SNP", "snp", "id", "trait")
	# write.csv(so, paste0("../results/01/upload/so-", i, ".csv"), row.names=FALSE, na=")
}

cmd <- paste0(
"~/neo4j-community-3.2.0/bin/neo4j-admin import", 
" --database mr-eve.db", 
" --id-type string", 
" --nodes:gene ../results/01/upload/genes.csv", 
" --nodes:snp ../results/01/upload/snps.csv", 
" --nodes:trait ../results/01/upload/traits.csv", 
" --relationships:GS ../results/01/upload/gene_snp.csv", 
" --relationships:GA ../results/01/upload/snp_trait.csv", 
" --relationships:MR ../results/01/upload/trait_trait.csv"
)
# system(cmd)
