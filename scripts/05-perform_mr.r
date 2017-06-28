# devtools::install_github("MRCIEU/TwoSampleMR@mr_structure")
library(TwoSampleMR)
library(tidyverse)
library(randomForest)

Isq <- function(y,s)
{
	k <- length(y)
	w <- 1/s^2
	sum.w <- sum(w)
	mu.hat <- sum(y*w)/sum.w
	Q <- sum(w*(y-mu.hat)^2)
	Isq <- (Q - (k-1))/Q
	Isq <- max(0,Isq)
	return(Isq)
}

system_metrics <- function(dat)
{
	library(car)

	# Number of SNPs
	# Sample size outcome
	# Sample size exposure
	metrics <- list()
	metrics$nsnp <- nrow(dat)
	metrics$nout <- mean(dat$samplesize.outcome, na.rm=TRUE)
	metrics$nexp <- mean(dat$samplesize.exposure, na.rm=TRUE)

	# F stats
	Fstat <- qf(dat$pval.exposure, 1, dat$samplesize.exposure, lower.tail=FALSE)
	Fstat[is.infinite(Fstat)] <- 300
	metrics$meanF <- mean(Fstat, na.rm=TRUE)
	metrics$varF <- var(Fstat, na.rm=TRUE)
	metrics$medianF <- median(Fstat, na.rm=TRUE)

	# IF more than 1 SNP

	if(nrow(dat) > 1)
	{
		# Egger-Isq
		metrics$egger_isq <- Isq(dat$beta.exposure, dat$se.exposure)
	}

	if(nrow(dat) > 2)
	{	
		# IF more than 2 SNP
		ruck <- mr_rucker(dat)

		# Q_ivw
		# Q_egger
		# Q_diff
		metrics$Isq <- (ruck$Q$Q[1] - (ruck$Q$df[1]-1))/ruck$Q$Q[1]
		metrics$Isqe <- (ruck$Q$Q[2] - (ruck$Q$df[2]-1))/ruck$Q$Q[2]
		metrics$Qdiff <- ruck$Q$Q[3]

		# Intercept / se
		metrics$intercept <- abs(ruck$intercept$Estimate[1]) / ruck$intercept$SE[1]

		# Influential outliers
		dfbeta_thresh <- 2 * nrow(dat)^-0.5
		cooksthresh1 <- 4 / (nrow(dat) - 2)
		cooksthresh2 <- 4 / (nrow(dat) - 3)
		inf1 <- influence.measures(ruck$lmod_ivw)$infmat
		inf2 <- influence.measures(ruck$lmod_egger)$infmat
		metrics$dfb1_ivw <- sum(inf1[,1] > dfbeta_thresh) / nrow(dat)
		metrics$dfb2_ivw <- sum(inf1[,2] > dfbeta_thresh) / nrow(dat)
		metrics$dfb3_ivw <- sum(inf1[,3] > dfbeta_thresh) / nrow(dat)
		metrics$cooks_ivw <- sum(inf1[,4] > cooksthresh1) / nrow(dat)
		metrics$dfb1_egger <- sum(inf2[,1] > dfbeta_thresh) / nrow(dat)
		metrics$dfb2_egger <- sum(inf2[,2] > dfbeta_thresh) / nrow(dat)
		metrics$dfb3_egger <- sum(inf2[,3] > dfbeta_thresh) / nrow(dat)
		metrics$cooks_egger <- sum(inf2[,4] > cooksthresh2) / nrow(dat)

		# Homoscedasticity
		metrics$homosc_ivw <- car::ncvTest(ruck$lmod_ivw)$ChiSquare
		metrics$homosc_egg <- car::ncvTest(ruck$lmod_egger)$ChiSquare

		# Normality of residuals
		metrics$shap_ivw <- shapiro.test(residuals(ruck$lmod_ivw))$statistic
		metrics$shap_egger <- shapiro.test(residuals(ruck$lmod_egger))$statistic
		metrics$ks_ivw <- ks.test(residuals(ruck$lmod_ivw), "pnorm")$statistic
		metrics$ks_egger <- ks.test(residuals(ruck$lmod_egger), "pnorm")$statistic

	}
	return(metrics)
}

get_metrics <- function(dat)
{
	metrics <- system_metrics(dat)
	# Steiger
	steiger_keep <- dat$steiger_dir
	metrics$st_correct <- sum(steiger_keep) / nrow(dat)
	metrics$st_unknown <- sum(dat$steiger_pval < 0.05) / nrow(dat)
	metrics$st_incorrect <-  sum(!dat$steiger_dir & dat$steiger_pval < 0.05) / nrow(dat)

	dat2 <- dat[steiger_keep, ]
	if(nrow(dat2) > 0)
	{
		metrics2 <- system_metrics(dat2)
		names(metrics2) <- paste0(names(metrics2), "_after_steiger")
		metrics <- c(metrics, metrics2)
	}
	return(metrics)
}

# find all m2 for which there are at least 5 SNPs
# return a combined data frame of all estimates including rf

get_rf_method <- function(m1, m2, d, rf)
{
	j <- 1
	nom <- names(rf)
	l <- list()
	n <- list()
	d$samplesize.exposure[is.na(d$samplesize.exposure)] <- 10000
	d$samplesize.outcome[is.na(d$samplesize.outcome)] <- 10000
	for(i in 1:length(m2))
	{
		message(i)
		id.e <- attributes(m2)$id.exposure[i]
		id.o <- attributes(m2)$id.outcome[i]
		e <- attributes(m2)$exposure[i]
		o <- attributes(m2)$outcome[i]
		k <- which(attributes(m1)$id.exposure == id.e & attributes(m1)$id.outcome == id.o)[1]
		res1 <- m1[[k]]$out
		res1$Method <- paste0(res1$Method, " - tophits")
		res2 <- m2[[i]]$out
		res2$Method <- paste0(res2$Method, " - steiger")
		res <- bind_rows(res1, res2)
		if(nrow(m2[[i]]$dat) > 5)
		{
			message("RF")
			ds <- subset(d, id.exposure == id.e & id.outcome == id.o)
			met <- get_metrics(ds) %>% as.data.frame()
			pr <- rep(0, length(rf))
			for(i in 1:length(pr))
			{
				pr[i] <- predict(rf[[i]], met)
			}
			pr <- tibble(pr=pr, Method=nom)
			res <- left_join(res, pr, by="Method")
			ress <- res[which.max(res$pr)[1], ]
			n[[j]] <- tibble(id.exposure=id.e, id.outcome=id.o, exposure=e, outcome=o, selected_method=ress$Method)
			ress$Method <- "RF"
			l[[j]] <- rbind(res, ress)
			j <- j + 1
		}
	}
	attributes(l) <- bind_rows(n)
	return(l)
}



ds <- "01"

load(paste0("../results/", ds, "/outcome_nodes.rdata"))
load(paste0("../results/", ds, "/exposure_dat.rdata"))
load("~/repo/instrument-directionality/results/rf.rdata")


i <- as.numeric(commandArgs(T)[1])

load(paste0("../results/01/dat/dat-", outcome_nodes$id[i], ".rdata"))
d$outcome <- outcome_nodes$trait[i]


a <- subset(d, id.exposure == 2)
run_mr(a)

m1 <- run_mr(subset(d, id.exposure != id.outcome))
save(m1, file=paste0("../results/01/mr/m1-", outcome_nodes$id[i], ".rdata"))
m2 <- run_mr(subset(d, id.exposure != id.outcome & steiger_dir))
save(m2, file=paste0("../results/01/mr/m2-", outcome_nodes$id[i], ".rdata"))
m3 <- get_rf_method(m1, m2, d, rf)
save(m3, file=paste0("../results/01/mr/m3-", outcome_nodes$id[i], ".rdata"))

