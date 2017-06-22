# westra
# simple clumping

library(tidyverse)
library(TwoSampleMR)
library(data.table)

a <- fread("../data/2012-12-21-CisAssociationsProbeLevelFDR0.5.txt")
b <- filter(a, PValue < 5e-5) %>%
	arrange(PValue) %>%
	filter(!duplicated(ProbeName))

write.table(unique(b$SNPName), file="westrasnps.txt", row=F, col=F, qu=F)
system(
	"plink1.90 --bfile ~/data/alspac_1kg/data/derived/filtered/bestguess/maf0.01_info0.8/combined/data --extract westrasnps.txt --freq --out westrasnps.txt"
)

fr <- fread("westrasnps.txt.frq")

b <- inner_join(b, dplyr::select(fr, SNP, MAF), by=c("SNPName"="SNP"))

b$n <- 5300
b$r <- get_r_from_pn(b$PValue, b$n)
b$rsq <- b$r^2

b$eff <- sqrt(b$rsq /(2 * b$MAF * (1-b$MAF)))
b$se <- b$eff / b$OverallZScore

temp <- do.call(rbind, strsplit( b$SNPType, "/"))
index <- temp[,1] == b$AlleleAssessed
b$otherallele <- NA
b$otherallele[index] <- temp[index, 2]
b$otherallele[!index] <- temp[!index, 1]


westra <- with(b,
	tibble(
		SNP=SNPName,
		exposure=ProbeName,
		id.exposure=ProbeName,
		beta.exposure=eff,
		se.exposure=se,
		pval.exposure=PValue,
		effect_allele.exposure=AlleleAssessed,
		other_allele.exposure=otherallele,
		genename=HUGO,
		probechr=ProbeChr,
		probecentre=ProbeCenterChrPos
	)
)

save(westra, file="../data/westra.rdata")

