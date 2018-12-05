library(dplyr)
library(TwoSampleMR)
library(magrittr)
a <- read.csv("derived/instruments/master_list.csv.gz", he=F, stringsAsFactors=FALSE)
b <- read.csv("../2/derived/instruments/master_list.csv.gz", he=F, stringsAsFactors=FALSE)

b <- subset(b, V3==1)
a <- subset(a, V1 %in% b$V1)

table(a$V4 == b$V4)
table(a$V5 == b$V5)
table(a$V1 == b$V1)

mr_ivw(b$V6, a$V6, b$V7, a$V7)

library(data.table)
x <- fread("../2/derived/instruments/master_list.csv.gz", header=FALSE) %>% subset(V3 == 1)
y <- fread("derived/instruments/master_list.csv.gz", header=FALSE)

make_dat <- function(x, y)
{
	x <- x %$% data_frame(
		id.exposure=V2,
		exposure=V2,
		SNP=V1, 
		effect_allele.exposure=V4, 
		other_allele.exposure=V5, 
		beta.exposure=V6, 
		se.exposure=V7, 
		eaf.exposure=V8, 
		samplesize.exposure=V9, 
		pval.exposure=V10)
	y <- y %$% data_frame(
		id.outcome=V2,
		outcome=V2,
		SNP=V1, 
		effect_allele.outcome=V4, 
		other_allele.outcome=V5, 
		beta.outcome=V6, 
		se.outcome=V7, 
		eaf.outcome=V8, 
		samplesize.outcome=V9, 
		pval.outcome=V10)
	xy <- inner_join(x,y,by="SNP")
	xy$mr_keep <- TRUE
	mr(xy)
	run_mr(xy)

}


a <- list.files(pattern="*/derived/instruments/clump.txt")
head(a)





