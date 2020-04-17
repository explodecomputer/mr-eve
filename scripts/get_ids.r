library(ieugwasr)
library(dplyr)

args <- commandArgs(T)
idlist <- args[1]
gwasdir <- args[2]
output <- args[3]

idlist <- scan(idlist, what="character")

idinfo <- ieugwasr::gwasinfo(idlist) %>%
	mutate(file=file.path(gwasdir, id, paste0(id, ".vcf.gz")))

save(idinfo, file=output)
