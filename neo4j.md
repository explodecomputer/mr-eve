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



## Construction

Need to get the neo4j server software to construct the graph

```
wget https://neo4j.com/artifact.php?name=neo4j-community-3.5.3-unix.tar.gz
```

This is a reduced version, just mr-moe

```
rm -rf ~/mr-eve/neo4j/neo4j-enterprise-3.5.3/data/databases/graph.db
~/mr-eve/neo4j/neo4j-enterprise-3.5.3/bin/neo4j-admin import \
--database graph.db \
--id-type string \
--nodes:GENE resources/neo4j_stage/genes.csv.gz \
--nodes:VARIANT resources/neo4j_stage/variants.csv.gz \
--nodes:TRAIT resources/neo4j_stage/traits.csv.gz \
--relationships:ANNOTATION resources/neo4j_stage/gv.csv.gz \
--relationships:INSTRUMENT resources/neo4j_stage/instruments.csv.gz \
--relationships:MRMOE resources/neo4j_stage/mrmoe1.csv.gz,resources/neo4j_stage/mrmoe2.csv.gz,resources/neo4j_stage/mrmoe3.csv.gz,resources/neo4j_stage/mrmoe4.csv.gz,resources/neo4j_stage/mrmoe5.csv.gz,resources/neo4j_stage/mrmoe6.csv.gz,resources/neo4j_stage/mrmoe7.csv.gz,resources/neo4j_stage/mrmoe8.csv.gz
```

To create full graph

```
rm -rf ~/mr-eve/neo4j/neo4j-enterprise-3.5.3/data/databases/graph.db
~/mr-eve/neo4j/neo4j-enterprise-3.5.3/bin/neo4j-admin import \
--database graph.db \
--id-type string \
--nodes:GENE resources/neo4j_stage/genes.csv.gz \
--nodes:VARIANT resources/neo4j_stage/variants.csv.gz \
--nodes:TRAIT resources/neo4j_stage/traits.csv.gz \
--relationships:ANNOTATION resources/neo4j_stage/gv.csv.gz \
--relationships:INSTRUMENT resources/neo4j_stage/instruments.csv.gz \
--relationships:GENASSOC resources/neo4j_stage/vt1.csv.gz,resources/neo4j_stage/vt2.csv.gz,resources/neo4j_stage/vt3.csv.gz,resources/neo4j_stage/vt4.csv.gz,resources/neo4j_stage/vt5.csv.gz,resources/neo4j_stage/vt6.csv.gz,resources/neo4j_stage/vt7.csv.gz,resources/neo4j_stage/vt8.csv.gz \
--relationships:MR resources/neo4j_stage/mr1.csv.gz,resources/neo4j_stage/mr2.csv.gz,resources/neo4j_stage/mr3.csv.gz,resources/neo4j_stage/mr4.csv.gz,resources/neo4j_stage/mr5.csv.gz,resources/neo4j_stage/mr6.csv.gz,resources/neo4j_stage/mr7.csv.gz,resources/neo4j_stage/mr8.csv.gz \
--relationships:MRMOE resources/neo4j_stage/mrmoe1.csv.gz,resources/neo4j_stage/mrmoe2.csv.gz,resources/neo4j_stage/mrmoe3.csv.gz,resources/neo4j_stage/mrmoe4.csv.gz,resources/neo4j_stage/mrmoe5.csv.gz,resources/neo4j_stage/mrmoe6.csv.gz,resources/neo4j_stage/mrmoe7.csv.gz,resources/neo4j_stage/mrmoe8.csv.gz \
--relationships:MRINTERCEPT resources/neo4j_stage/mrintercept1.csv.gz,resources/neo4j_stage/mrintercept2.csv.gz,resources/neo4j_stage/mrintercept3.csv.gz,resources/neo4j_stage/mrintercept4.csv.gz,resources/neo4j_stage/mrintercept5.csv.gz,resources/neo4j_stage/mrintercept6.csv.gz,resources/neo4j_stage/mrintercept7.csv.gz,resources/neo4j_stage/mrintercept8.csv.gz \
--relationships:MRHET resources/neo4j_stage/mrhet1.csv.gz,resources/neo4j_stage/mrhet2.csv.gz,resources/neo4j_stage/mrhet3.csv.gz,resources/neo4j_stage/mrhet4.csv.gz,resources/neo4j_stage/mrhet5.csv.gz,resources/neo4j_stage/mrhet6.csv.gz,resources/neo4j_stage/mrhet7.csv.gz,resources/neo4j_stage/mrhet8.csv.gz \
--relationships:METRICS resources/neo4j_stage/metrics1.csv.gz,resources/neo4j_stage/metrics2.csv.gz,resources/neo4j_stage/metrics3.csv.gz,resources/neo4j_stage/metrics4.csv.gz,resources/neo4j_stage/metrics5.csv.gz,resources/neo4j_stage/metrics6.csv.gz,resources/neo4j_stage/metrics7.csv.gz,resources/neo4j_stage/metrics8.csv.gz
```

Then run the `neo4j/deploy.sh` to rsync to docker cluster, create container and point to the database