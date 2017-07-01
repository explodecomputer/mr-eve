#/bin/bash

module add languages/java-jdk-1.8.0-66

neo4j_dir=""
cat ../results/01/upload/trait_trait* > ../results/01/upload/trait_trait.csv
cat ../results/01/upload/trait_trait_sel* ../results/01/upload/trait_trait_sel.csv


${neo4j_dir}/bin/neo4j-import \
--into ../results/01/upload/mr-eve.db \
--id-type string \
--nodes:gene ../data/upload/genes.csv \
--nodes:snp ../data/upload/snps.csv \
--nodes:trait ../data/upload/traits.csv \
--relationships:GS ../data/upload/gene_snp.csv \
--relationships:GA ../data/upload/snp_trait.csv \
--relationships:MR ../data/upload/trait_trait.csv \
--relationships:MRB ../data/upload/trait_trait_sel.csv

scp -rv mr-eve.db gh13047@shark.epi.bris.ac.uk:neo4j/data/mreve.db





#####


#/bin/bash

module add languages/java-jdk-1.8.0-66

neo4j_dir="~/bin/neo4j-community-3.2.1"
cat ../results/01/upload/trait_trait* > ../results/01/upload/trait_trait.csv
cat ../results/01/upload/trait_trait_sel* > ../results/01/upload/trait_trait_sel.csv


bin/neo4j-import \
--into mr-eve.db \
--id-type string \
--nodes:gene data/upload/genes.csv \
--nodes:snp data/upload/snps.csv \
--nodes:trait data/upload/traits.csv \
--relationships:GS data/upload/gene_snp.csv \
--relationships:GA data/upload/snp_trait.csv \
--relationships:MRB data/upload/trait_trait_sel.csv \
--relationships:MR data/upload/trait_trait.csv

scp -prv ../results/01/upload/mr-eve.db/. gh13047@shark.epi.bris.ac.uk:neo4j/data/mr-eve.db/



rm -r ../results/01/upload/trait_trait.csv
rm -r ../results/01/upload/trait_trait_sel.csv
for i in {1..8}
do
	cat ../results/01/upload/trait_trait-${i}.csv >> ../results/01/upload/trait_trait.csv
	cat ../results/01/upload/trait_trait_sel-${i}.csv >> ../results/01/upload/trait_trait_sel.csv
done


for i in {2..8}
do
	echo $i
	sed -i 1d trait_trait-${i}.csv
	sed -i 1d trait_trait_sel-${i}.csv
done


docker run -d --publish=7474:7474 --volume=$HOME/neo4j/data:/data --volume=$HOME/neo4j/logs:/logs neo4j:2.3
docker exec -i -t boring_panini /bin/bash


docker run \
    --publish=7474:7474 \
    --volume=$HOME/neo4j/data:/data \
    --volume=$HOME/neo4j/logs:/logs \
    neo4j:2.3



match (n:trait)-[rels:MRB*1..2]->(m:trait) where all (rel in rels where rel.P < 0.001) return count(rels)

match (n:trait)-[rel1:MRB]->(m:trait)-[rel2:MRB]->(o:trait), (n:trait)-[rel3:MRB]->(o:trait) where rel1.P < 0.001 and rel2.P < 0.001 and rel3.P > 0.05 return n.name, m.name, o.name, rel1.P, rel2.P, rel3.P limit 10


match (n:trait)-[rel1:MRB]->(m:trait)-[rel2:MRB]->(o:trait), (n:trait)-[rel3:MRB]->(o:trait) where rel1.P < 0.001 and rel2.P < 0.001 and rel3.P > 0.05 return count(rel3)


match (n:trait)-[rels:MR]->(m:trait) where rels.P < 0.0001

38013


