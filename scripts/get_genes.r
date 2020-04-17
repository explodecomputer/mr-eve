library(biomaRt)
library(dplyr)
library(GenomicRanges)

args <- commandArgs(T)
output <- args[1]

ensembl <- useEnsembl(biomart="ensembl", dataset="hsapiens_gene_ensembl", GRCh=37)
genes <- lapply(c(1:22, "X", "Y"), function(x) {
	message(x)
	a <- getBM(attributes=c('ensembl_gene_id', 'ensembl_transcript_id','hgnc_symbol','chromosome_name','start_position','end_position', 'gene_biotype', 'strand'), filters = 'chromosome_name', values = x, mart = ensembl)
	a$chromosome_name <- as.character(a$chromosome_name)
	a
}) %>% bind_rows() %>% as_tibble()

genes$strand <- gsub("1", "+", gsub("-1", "-", as.character(genes$strand)))

genesgr <- genes %>% {
	GRanges(
		.$chromosome_name,
		IRanges(start = .$start_position, end = .$end_position),
		ensembl_gene_id = .$ensembl_gene_id,
		strand = .$strand,
		hgnc_symbol = .$hgnc_symbol,
		gene_biotype = .$gene_biotype
	)}
save(genesgr, file=output)
