1. Select traits
2. Get instruments for traits
3. Extract SNPs from outcomes
4. Harmonise data
5. Perform MR
6. Upload to neo4j

7. Add new traits
    - add to existing traits
    - get instruments and find unique instruments
    - extract all outcome SNPs for new trait, and new instruments from other traits
    - harmonise data
    - perform MR
    - upload to neo4j




## 

need two files

- node information
- mr estimates
- heterogeneity stats
- 





neo4j

to run in background:

docker run -d --publish=7474:7474 --volume=$HOME/neo4j/data:/data neo4j:2.3
docker exec -i -t neo4j:2.3 /bin/bash


./neo4j-import \
--into mr-eve.db \
--id-type string \
--nodes:gene ../data/upload/genes.csv \
--nodes:snp ../data/upload/snps.csv \
--nodes:trait ../data/upload/traits.csv \
--relationships:GS ../data/upload/gene_snp.csv \
--relationships:GA ../data/upload/snp_trait.csv \
--relationships:MR ../data/upload/trait_trait.csv











the paper

the causal map of the human phenome: a first draft

- intro
    - methods and data enable faster causal inference
    - hypothesis driven analysis should use all methods to scrutinise
    - we can precalculate these estimates but automation requires a number of things still
        - instrument selection using steiger test
        - method selection using linear discriminant analysis
    - here we introduce a comprehensive analysis of 150 traits, introducing two ways for automating instrument selection and method selection

- results
    - created graph
    - steiger method simulations
    - method selection simulations

