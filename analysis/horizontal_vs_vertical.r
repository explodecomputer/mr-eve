library(ggplot2)
library(ggrepel)
library(dplyr)
library(mrever)


# compare the magnitude of vertical vs horizontal pleiotropy

simple_r2 <- function(b, se, n)
{
	f <- b^2 / se^2
	r2 <- f / (n + f - 2)
	return(r2)
}

estimate_trait_sd <- function(b, se, n, p)
{
	z <- b / se
	standardised_bhat <- sqrt((z^2/(z^2+n-2)) / (2 * p * (1-p))) * sign(z)
	estimated_sd <- b / standardised_bhat
	return(median(estimated_sd, na.rm=T))
}

adjr2 <- function(r2, n)
{
	1 - (1 - sum(r2)) * (n - 1) / (n - length(r2) - 1)
}


calc_plei <- function(exp, exp_rep, out, adj=FALSE)
{
	a <- get_instruments(exp)	
	arep <- get_genassoc(a$variantId, exp_rep)
	b <- get_genassoc(a$variantId, out)
	biv <- get_mr(exp, out)$mr %>% filter(!is.na(moescore)) %>% arrange(desc(moescore)) %>% slice(1) %>% .$b
	arep$rsq <- simple_r2(arep$beta, arep$se, arep$samplesize)
	b$rsq <- simple_r2(b$beta, b$se, b$samplesize)
	if(all(is.na(b$eaf)))
	{
		temp <- merge(a, b, by="variantId")
		vy <- estimate_trait_sd(temp$beta.y, temp$se.y, temp$samplesize.y, temp$eaf.x)^2
	} else {
		vy <- estimate_trait_sd(b$beta, b$se, b$samplesize, b$eaf)^2
	}
	ivr2 <- biv^2 * estimate_trait_sd(a$beta, a$se, a$samplesize, a$eaf)^2 / vy

	if(adj)
	{
		totalr2 <- adjr2(b$rsq, median(b$samplesize))
		mediatedr2 <- adjr2(arep$rsq * ivr2, median(b$samplesize))
	} else {
		mediatedr2 <- sum(arep$rsq * ivr2, na.rm=TRUE)
		totalr2 <- sum(b$rsq, na.rm=TRUE)
	}

	return(tibble(exp=exp, exp_rep=exp_rep, out=out, nsnp=nrow(a), ivr2=ivr2, totalr2=totalr2, mediatedr2=mediatedr2, propmediated=mediatedr2 / totalr2))
}


# Get list of traits to do phewas

traits <- get_traits()
p <- phewas(2) %>% subset(p.adjust(pval, "fdr") < 0.05)
tr <- subset(traits, select=c(bgcidId, trait))
p <- merge(p, tr, by.x="outcome", by.y="bgcidId")


# Do pleiotropy estimation across traits

o1 <- list()
o2 <- list()
for(i in 1:nrow(p))
{
	message(i)
	o1[[i]] <- try(calc_plei("UKB-a:248", 2, p$outcome[i]))
	if(class(o1[[i]]) == "try-error") o1[[i]] <- NULL
	o2[[i]] <- try(calc_plei(2, "UKB-a:248", p$outcome[i]))
	if(class(o2[[i]]) == "try-error") o2[[i]] <- NULL
}

O1 <- bind_rows(o1)
O2 <- bind_rows(o2)
O1$exp <- as.character(O1$exp)
O1$out <- as.character(O1$out)
O1$exp_rep <- as.character(O1$exp_rep)
O2$exp <- as.character(O2$exp)
O2$out <- as.character(O2$out)
O2$exp_rep <- as.character(O2$exp_rep)
o <- bind_rows(O1,O2)
o <- merge(o, tr, by.x="out", by.y="bgcidId")


# Find traits to remove because of being either the same as BMI, or metabolites that don't scale 


ggplot(o, aes(x=ivr2, y=propmediated)) +
geom_point(aes(colour=exp)) +
geom_text_repel(data=subset(o, ivr2 > 0.3), aes(label=trait), size=2)

blacklist <- c("body mass", "body fat", "fat ", "Imped", "hip circ", "waist", "weight", "obes", "predicted mass", "body size", "difference", "body water", "fat-free")
blacklist <- c(blacklist)

blacklistid <- lapply(blacklist, function(x) subset(p, grepl(x, trait, ignore.case=TRUE))) %>% bind_rows() %>% .$outcome

blacklistid <- c(blacklistid, subset(traits, author == "Shin")$bgcidId)
blacklistid <- c(blacklistid, subset(traits, author == "Roederer")$bgcidId)

oc <- subset(o, !out %in% blacklistid)

# Plot the propmediated distributions between the two studies

ggplot(oc, aes(x=ivr2, y=propmediated)) +
geom_point(aes(colour=exp)) +
geom_text_repel(data=subset(oc, ivr2 > 0.3), aes(label=trait), size=2)
ggsave("../images/hv_scatter.pdf")


oc$label <- "GIANT - 79 SNPs"
oc$label[oc$exp == "UKB-a:248"] <- "UKBB - 314 SNPs"
ggplot(oc, aes(x=propmediated)) +
geom_density(aes(fill=label), alpha=0.6) +
labs(x="Vertical / (Vertical + Horizontal)", fill="") +
theme(legend.position=c(0.8, 0.8))
ggsave("../images/hv_density.pdf")

save(o, oc, p, traits, file="../results/horizontal_vs_vertical.rdata")
