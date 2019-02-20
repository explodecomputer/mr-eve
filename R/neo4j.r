modify_node_headers_for_neo4j <- function(x, id, idname)
{
	id_col <- which(names(x) == id)
	cl <- sapply(x, class)
	for(i in 1:length(cl))
	{
		if(cl[i] == "integer")
		{
			names(x)[i] <- paste0(names(x)[i], ":INT")
		}
		if(cl[i] == "numeric")
		{
			names(x)[i] <- paste0(names(x)[i], ":FLOAT")
		}
	}
	names(x)[id_col] <- paste0(idname, "Id:ID(", idname, ")")
	return(x)
}

modify_rel_headers_for_neo4j <- function(x, id1, id1name, id2, id2name)
{
	id1_col <- which(names(x) == id1)
	id2_col <- which(names(x) == id2)
	cl <- sapply(x, class)
	for(i in 1:length(cl))
	{
		if(cl[i] == "integer")
		{
			names(x)[i] <- paste0(names(x)[i], ":INT")
		}
		if(cl[i] == "numeric")
		{
			names(x)[i] <- paste0(names(x)[i], ":FLOAT")
		}
	}
	names(x)[id1_col] <- paste0(":START_ID(", id1name, ")")
	names(x)[id2_col] <- paste0(":END_ID(", id2name, ")")
	return(x)
}
