# Get exposure SNPs

library(tidyverse)
library(TwoSampleMR)
library(MRInstruments)

## Soma scan proteins

data(mrbase_instruments)
exposure_dat <- mrbase_instruments
save(exposure_dat, file="../results/03/exposure_dat.rdata")

