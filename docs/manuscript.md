## Introduction

Mendelian randomisation (MR) exploits genetic pleiotropy to infer the causal relationships between phenotypes. Suppose that one trait (the exposure) causally influences another (the outcome). If a SNP influences the outcome through the exposure then the SNP is exhibiting vertical pleiotropy. Such a genetic variant is known as an instrumental variable for the exposure, and can be exploited to mimic a randomised controlled trial, making causal inference by comparing the outcome phenotypes between those individuals that have the exposure-increasing allele against those who do not. Multiple independent genetic variants for a particular exposure can be used jointly to improve causal inference, the premise being that each variant is an independent natural experiment, and an overall causal estimate can be obtained by meta-analysing the single estimates from each instrument.

Genome-wide association studies (GWAS) have identified genetic instrumental variables for thousands of phenotypes. Recent developments in Mendelian randomisation have enabled knowledge of instrumental variables to be applied using only summary level data (known as two-sample MR, 2SMR). Here, in order to infer the causal effect of an exposure on an outcome all that is required is an estimate of the genetic effects of the instrumenting SNP on the exposure, and the corresponding estimate of the effect on the outcome. This has two major advantages. First, GWAS summary data is non-disclosive and often publicly available. Second, causal inference can be made between phenotypes even if they have not been measured in the same samples, limiting the breadth of possible causal estimates only to the availability of GWAS summary data for the traits in question.

Problems with obtaining unbiased causal effects can arise, however, if the genetic instruments exhibit horizontal pleiotropy (HP), where they influence the outcome through a pathway other than the exposure. The extent of this problem is not to be understated, and many methods have been developed that attempt to reliably obtain unbiased causal estimates under specific models of HP. It is considered best practice to report estimates from all available methods as sensitivity analyses when presenting causal estimates, however this strategy is not necessarily optimal for several reasons. First, if different methods disagree it is not possible to know which is correct because the appropriate model of HP is not known. Second, though the IVW approach is most statistically powerful under no HP, it can have high false negative or low true positive rates in the presence of HP compared to other methods. Given that pleiotropy has been hypothesised to be universal, defaulting to the IVW method in the first instance and using other methods as sensitivity analyses may not be appropriate. Third, the available methods do not cover all possible models of HP, and therefore an automated method for instrument selection may be necessary. Fourth, it could be of interest to make causal effect estimates for thousands of traits, in which case a discerning evaluation of each causal effect of interest may not be possible or convenient. 

In this paper we introduce new machine learning approaches that attempt to automate both instrument and method selection. Using curated GWAS summary data for thousands of phenotypes, we use these new methods to construct a graph of millions of causal estimates.


## Methods

### GWAS summary data and their use in 2SMR




### Mendelian randomisation methods and their assumptions

In this paper we consider three main classes of MR estimation. Full details for each approach have been described extensively elsewhere.

**Mean-based methods:** The inverse variance weighted (IVW) meta-analysis approach assumes that variant exhibits no HP (fixed effects meta-analysis) or that HP is present but balanced (random effects meta-analysis). Egger regression relaxes the HP assumption further by allowing the horizontal pleiotropy to systematically occur in a specific direction, known as directional horizontal pleiotropy. The Rucker framework uses estimates of heterogeneity to navigate between these nested models. A jackknife approach (random selection with replacement of instruments) can be used to obtain a sampling distribution for the model estimate amongst these four variations.

**Median-based methods:** An alternative approach is to take the median effect of all available instruments. This has the advantage that up to half the instruments can be invalid, and the estimate will remain unbiased. Developing the approach further to allow stronger instruments to contribute more towards the estimate can be obtained by obtaining the median of the weights of each instrument. The penalised weighted median estimator ...

**Mode-based methods:** Supposing that 


### Instrument selection

#### Top hits

The simplest approach to selecting instruments for performing MR is to take take SNPs that have been declared significant in the published GWAS for the exposure. This typically involves obtaining SNPs that surpass $p < 5 \times 10^{-8}$, using clumping to obtain independent SNPs, and then replicating in an independent sample. These results are often recorded in public GWAS catalogs. Alternatively the clumping procedure can be performed using complete summary data in MR-Base. We call this the "top hits" strategy.


#### Steiger filtering

With genome-wide association studies growing ever larger, the statistical power to detect significant associations that may be influencing the trait downstream of many other pathways increases. For example, if a SNP $g_{A}$ influences trait $A$, and trait $A$ influences trait $B$, then a sufficiently powered GWAS will identify the $g_{A}$ as being significant for trait $B$ (Figure 1a). Using $g_{A}$ as an instrument to test the causal effect of $A$ on $B$ is perfectly valid. But in the (incorrectly hypothesised) MR analysis of trait $B$ on trait $A$ could erroneously result in the apparent causal association of $B$ on $A$. If $g_{A}$ is only one of many known instruments for $B$, amongst which some are valid, it is to the advantage of the researcher to exclude $g_{A}$ from the analysis. 

An approach to inferring the causal direction between phenotypes was developed recently, using the following basic premise. If trait $A$ causes trait $B$ then 

$$
\sum^M_{i=1}{cor(g_{i}, A)^2} > \sum^M_{i=1}{cor(g_{i}, B)^2}
$$

because the $cor(g_{i}, B)^2 = cor(A, B)^{2} cor(g_{i}, A)^{2}$. This simple inequality will not hold in some cases, for example $\rho_{x, x_o} < \rho_{x,y}\rho_{y,y_o}$ where $\rho_{x, x_o}$ and $\rho_{y, y_o}$ are the precision of the measurements of the $x$ and $y$. Steiger's Z-test of correlated correlations can be used to formally test the extent to which the two correlations are statistically different.

Here we adapt this approach to automatically filter SNPs that are liable to be invalid (Figure 1a). In this case the Steiger test applied to each variant in turn will identify $g_{A}$ as being unlikely to primarily associate with $B$ relative to $A$. Similarly, for SNPs that influence confounders of $A$ and $B$ or those variants that exhibit horizontal pleiotropy, the difference in $cor(g_{i}, A)^2$ and $cor(g_{i}, B)^2$ will be reduced, increasing the likelihood of the SNP being excluded because the Steiger Z-test is less likely to be significant.

### Competitive mixture of experts

We consider 14 MR methods, for which instruments can be supplied using two instrument selection strategies, leading to 28 methods in total. In the context of this analysis, each method is considered to be an 'expert', taking a set of SNP-exposure and SNP-outcome effect sizes and their standard errors as inputs. Our objective is to select the expert most likely to be correct for a specific MR analysis.

#### Mixture of experts

The mixture of experts (MoE) method is a machine learning approach which seeks to divide a parameter space into subdomains, such that a particular expert is used primarily for problems that reside in a subdomain relevant to that expert. In this case our objective is to identify characteristics of the SNP-exposure and SNP-outcome associations for which one specific MR method is most likely to yield highest statistical power for non-null associations, and lowest false discovery rates for null associations.

**Training and testing simulations**

The MoE is trained using simulations. We create a set of SNP-exposure and SNP-outcome effects and standard errors that can be fed into any of the 28 experts to obtain MR causal effects. The simulations seek to make as many different 'problematic' models of HP as possible.

We simulate two individual level datasets for which there are $N_x$ and $N_y$ samples, and $M$ SNPs, where each SNP has effect allele frequency of $p_m \sim U(0.05, 0.95)$. These datasets are used to obtain the SNP effects for the exposure trait $x$ and the outcome trait $y$, respectively. The $M$ SNPs can influence $x$ directly, $y$ directly, or some number of confounders $u_{k}$ directly. 

Phenotypes for $x$ and $y$ are constructed using

$$
x = \sum^{M_x}_{i}{\beta_{gx,x,i}g_{x,i}} + \sum^{M_y}_{j}{\beta_{gy,x,j}g_{y,j}} + \sum^{K}_{k}{\beta_{ux,k} u_{k}} + e_{x}
$$

where $\beta_{gx,x}$ is the vector of effects of each of the $M_x$ SNPs that influence $x$ primarily, $\beta_{gy,x}$ is the vector of effects for the $M_y$ SNPs on $x$, where the $M_y$ SNPs influence $y$ primarily but exhibit horizontal pleiotropic effects on $x$. We allow some proportion of these effects to be 0. $\beta_{ux}$ is the vector of effects of each of the $K$ confounders on $x$. Each $u_{k}$ variable is constructed using

$$
u = \sum^{M_u}_{l}{\beta_{gu,l}g_{l}} + e_{l}
$$

and finally $y$ is constructed using

$$
y = \beta_{x,y}x + \sum^{M_y}_{i}{\beta_{gy,y,j}g_{y,j}} + \sum^{M_x}_{j}{\beta_{gx,y,i}g_{x,i}} + \sum^{K}_{k}{\beta_{uy,k} u_{k}} + e_{y}
$$

where $\beta_{x,y}$ is the causal effect of $x$ on $y$. 


        nidx=sample(20000:500000, 1), 
        nidy=sample(20000:500000, 1), 
        nidu=0, 
        nu=sample(0:10, 1), 
        na=0,
        nb=0,
        var_x.y=sample(c(0, runif(5, 0.001, 0.1)), 1),
        nsnp_x=sample(1:200, 1),
        nsnp_y=sample(1:200, 1),
        var_gx.x=runif(1, 0.01, 0.1),
        var_gy.y=runif(1, 0.01, 0.1),
        var_gx.y=runif(1, 0.001, 0.01),
        mu_gx.y=runif(1, -0.005, 0.005),
        prop_gx.y=runif(1, 0, 1),
        var_gy.x=runif(1, 0.001, 0.01),
        mu_gy.x=runif(1, -0.005, 0.005),
        prop_gy.x=runif(1, 0, 1)

                nsnp_u=sample(5:30, 1), 
                var_u.x=runif(1, min=0.01, max=0.1), 
                var_u.y=runif(1, min=0.01, max=0.1), 
                var_gu.u=runif(1, min=0.02, 0.2)


**Strategy**

Figure 2a outlines the general strategy for the mixture of experts implementation. For a specific 

**Optimisation function** 





Figure 1