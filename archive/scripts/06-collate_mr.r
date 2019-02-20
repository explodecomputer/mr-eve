library(tidyverse)

# best causal estimate
# each other causal estimate
# other metrics


# best

# m2 = 1 SNP: wald ratio
# m2 = 5 SNP: ivw
# m2 = >5 SNP: RF
# m2 not in m1: 0 effect



# 1. Get the results

# For each SNP
# - rsq
# - steiger
# - evidence of being outlier
# - 


fn <- function(oid)
{
	require(tidyverse)
	m <- list()
	mb <- list()
	se <- list()
	so <- list()
	k <- 1
	for(i in 1:length(oid))
	{
		message(i)
		fn1 <- paste0("../results/01/mr/m1-", oid[i], ".rdata")
		fn2 <- paste0("../results/01/mr/m2-", oid[i], ".rdata")
		fn3 <- paste0("../results/01/mr/m3-", oid[i], ".rdata")
		if(file.exists(fn1) & file.exists(fn2) & file.exists(fn3))
		{
			load(fn1)
			load(fn2)
			load(fn3)
			a1 <- attributes(m1)$id.exposure
			a2 <- attributes(m2)$id.exposure
			a3 <- attributes(m3)$id.exposure

			for(j in 1:length(m1))
			{
				so[[k]] <- tibble(
					SNP=m1[[j]]$dat$SNP,
					beta=m1[[j]]$dat$beta.outcome,
					se=m1[[j]]$dat$se.outcome,
					pval=m1[[j]]$dat$pval.outcome,
					n=m1[[j]]$dat$samplesize.outcome,
					ea=m1[[j]]$dat$a1,
					oa=m1[[j]]$dat$a2,
					id=oid[i]
				)

				if(a1[j] %in% a3)
				{
					msel <- attributes(m3)$selected_method[which(a3 == a1[j])]

					if(!is.na(msel))
					{
						mb[[k]] <- subset(m3[[which(a3 == a1[j])]], Method == "RF")
						mb[[k]]$Method <- msel
					} else {
						mb[[k]] <- subset(m3[[which(a3 == a1[j])]], Method == "Simple mode - steiger")
					}
					m[[k]] <- m3[[which(a3 == a1[j])]]
					m[[k]] <- tidyr::separate(m[[k]], Method, c("Method", "instruments"), " - ")
				} else if(a1[j] %in% a2) {
					temp2 <- m2[[which(a2 == a1[j])]]$out
					temp2$instruments <- "steiger"
					temp1 <- m1[[j]]$out
					temp1$instruments <- "tophits"
					m[[k]] <- rbind(temp1, temp2)
					if("Simple mode" %in% m2$out$Method)
					{
						mb[[k]] <- m2[[which(a2 == a1[j])]]$out 
						mb[[k]] <- mb[[k]][mb[[k]]$Method == "Simple mode",]
					} else {
						mb[[k]] <- m2[[which(a2 == a1[j])]]$out[1,]
					}
					mb[[k]]$Method <- paste0(mb[[k]]$Method, " - steiger")
				} else {
					m[[k]] <- m1[[j]]$out
					m[[k]]$instruments <- "tophits"
					m[[k]] <- rbind(m[[k]], m[[k]][1,])
					m[[k]]$Method[nrow(m[[k]])] <- "Wald ratio"
					m[[k]]$Estimate[nrow(m[[k]])] <- 0
					m[[k]]$SE[nrow(m[[k]])] <- NA
					m[[k]]$CI_low[nrow(m[[k]])] <- NA
					m[[k]]$CI_upp[nrow(m[[k]])] <- NA
					m[[k]]$P[nrow(m[[k]])] <- 1
					m[[k]]$nsnp[nrow(m[[k]])] <- 0
					m[[k]]$instruments[nrow(m[[k]])] <- "steiger"
					mb[[k]] <- subset(m[[k]], select=-c(instruments))[2,]
					mb[[k]]$Method <- paste0(mb[[k]]$Method, " - steiger")
				}
				m[[k]]$id.exposure <- a1[j]
				m[[k]]$id.outcome <- oid[i]
				mb[[k]]$id.exposure <- a1[j]
				mb[[k]]$id.outcome <- oid[i]
				k <- k+1
			}
		}
	}
	return(list(m=m, mb=mb, so=so))
}


load("../results/01/outcome_nodes.rdata")
oid <- outcome_nodes$id


arg <- commandArgs(T)
jid <- as.numeric(arg[1])

message(jid)

start <- (jid -1) * 100 + 1
end <- min(jid * 100, nrow(outcome_nodes))

a <- fn(oid[start:end])
save(a, file=paste0("../results/01/mr/mc-", jid, ".rdata"))


