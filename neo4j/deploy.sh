#!/bin/bash

mkdir -p ~/mr-eve/neo4j/data
mkdir -p ~/mr-eve/neo4j/logs
rsync -avzh gh13047@bc4login.acrc.bris.ac.uk:mr-eve/neo4j/neo4j-enterprise-3.5.3/data/databases/mr-eve.db ~/mr-eve/neo4j/data

docker rm -f neo4j-eve-v4
docker run -d \
    --publish=8474:7474 --publish=8687:7687 \
    --volume=$HOME/mr-eve/neo4j/data:/data \
    --volume=$HOME/mr-eve/neo4j/logs:/logs \
    --user="$(id -u):$(id -g)" \
    --env=NEO4J_ACCEPT_LICENSE_AGREEMENT=yes \
    --name neo4j-eve-v4 \
    neo4j:3.5.3-enterprise




