library(RNeo4j)
graph <- RNeo4j::startGraph("http://shark.epi.bris.ac.uk:7474/db/data/", "neo4j", "123qwe")
bonf <- 0.05/715681

a <- cypher(graph,
	paste0("
		match (n:trait)-[r:MRB]->(m:trait) where r.P < ", bonf, " and r.nsnp >5 return r.Method AS Method, count(*) AS count order by count DESC")
)

b <- cypher(graph,
	paste0("
		match (n:trait)-[r:MR]->(m:trait) where r.P < ", bonf, " return r.Method+' - '+r.instruments AS Method, count(*) AS count order by count DESC")
)

b <- cypher(graph,
	paste0("
		match (n:trait)-[r:MRB]->(m:trait) where r.P < ", bonf, " return count(r)")
)


a <- cypher(graph,
	paste0("
		match (n:trait)-[r:MRB]->(m:trait) where r.nsnp > 5 return r.Method AS Method, count(*) AS count order by count DESC")
)

a <- cypher(graph,
	paste0("
		match (n:trait)-[r:MRB]->(m:trait) where r.nsnp > 5 return r.Method AS Method, count(*) AS count order by count DESC")
)


cypher(graph,
	paste0("
		match (n:trait)-[r1:MRB]->(m:trait),
		 (m:trait)-[r2:MRB]->(n:trait)

		where r1.P < 7e-8 and r2.P < 7e-8
		return n.name, m.name
	")
)



