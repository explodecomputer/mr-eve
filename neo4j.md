# Schema for neo4j

## Nodes:

VARIANT
- rsid
- chr
- pos
- build
- ea
- nea

GENE
- name
- tss
- length

TRAIT
- mrbid
- name
- etc


## Relationships:

GENASSOC (VARIANT->TRAIT)
- eaf
- beta
- se
- pval
- proxy

INSTRUMENT (VARIANT->TRAIT)
- eaf
- beta
- se
- pval

MR (TRAIT->TRAIT)
- method
- filter
- nsnp
- beta
- se
- pval
- moescore
- n_exp
- n_out
- ncase_exp
- ncase_out
- ncontrol_exp
- ncontrol_out

MRMOE (TRAIT->TRAIT)
- method
- filter
- nsnp
- beta
- se
- moescore

MRHET (TRAIT-TRAIT)
- method
- filter
- q
- df
- isq
- pval

MRINTERCEPT (TRAIT-TRAIT)
- method
- filter
- nsnp
- beta
- se
- pval

ANNOTATION (GENE-VARIANT)
- tss_dist

METRICS (TRAIT-TRAIT)
- all the metrics

