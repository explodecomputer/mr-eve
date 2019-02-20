#/bin/bash

# On the server run:
# docker run -d \
# --name neo4j321 \
# --publish=7475:7474  --publish=7687:7687 \
# --volume=$HOME/neo4j/data3.2:/data \
# --volume=$HOME/neo4j/logs3.2:/logs \
# neo4j:3.2.1

# docker exec -i -t neo4j321 /bin/bash
# bolt://shark.epi.bris.ac.uk:7687

# docker run -d \
# --name neo4j23 \
# --publish=7474:7474 \
# --volume=$HOME/neo4j/data:/data \
# --volume=$HOME/neo4j/logs:/logs \
# neo4j:2.3

# docker exec -i -t neo4j321 /bin/bash

# sudo chown --recursive gh13047 neo4j/data3.2
# mv neo4j/data3.2/databases/graph.db neo4j/data3.2/databases/graph.db_old



module add languages/java-jdk-1.8.0-66

neo4j_dir="/panfs/panasas01/sscm/gh13047/bin/neo4j-community-3.2.1"

rm -f ../results/01/upload/trait_trait.csv
rm -f ../results/01/upload/trait_trait_sel.csv
cp ../results/01/upload/trait_trait-1.csv ../results/01/upload/trait_trait.csv
cp ../results/01/upload/trait_trait_sel-1.csv ../results/01/upload/trait_trait_sel.csv

for i in {2..8}
do
	echo $i
	sed 1d ../results/01/upload/trait_trait-${i}.csv >> ../results/01/upload/trait_trait.csv
	sed 1d ../results/01/upload/trait_trait_sel-${i}.csv >> ../results/01/upload/trait_trait_sel.csv
done

rm -rf ../results/01/upload/graph.db

${neo4j_dir}/bin/neo4j-import \
--into ../results/01/upload/graph.db \
--id-type string \
--nodes:gene ../results/01/upload/genes.csv \
--nodes:snp ../results/01/upload/snps.csv \
--nodes:trait ../results/01/upload/traits.csv \
--relationships:GS ../results/01/upload/gene_snp.csv \
--relationships:GA ../results/01/upload/snp_trait.csv \
--relationships:MR ../results/01/upload/trait_trait.csv \
--relationships:MRB ../results/01/upload/trait_trait_sel.csv

scp -prv ../results/01/upload/*csv gh13047@shark.epi.bris.ac.uk:neo4j/data3.2/


exit


#####



rm -rf data/databases/graph.db

./bin/neo4j-import \
--into data/databases/graph.db \
--id-type string \
--nodes:gene data/genes.csv \
--nodes:snp data/snps.csv \
--nodes:trait data/traits.csv \
--relationships:GS data/gene_snp.csv \
--relationships:GA data/snp_trait.csv \
--relationships:MR data/trait_trait.csv \
--relationships:MRB data/trait_trait_sel.csv



rm -r ../results/01/upload/trait_trait.csv
rm -r ../results/01/upload/trait_trait_sel.csv
for i in {1..8}
do
	cat ../results/01/upload/trait_trait-${i}.csv >> ../results/01/upload/trait_trait.csv
	cat ../results/01/upload/trait_trait_sel-${i}.csv >> ../results/01/upload/trait_trait_sel.csv
done



docker run -d --publish=7474:7474 --volume=$HOME/neo4j/data:/data --volume=$HOME/neo4j/logs:/logs neo4j:2.3
docker exec -i -t focused_williams /bin/bash


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


