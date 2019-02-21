#' Modify headers for neo4j
#'
#'
#' @param x <what param does>
#' @param id <what param does>
#' @param idname <what param does>
#'
#' @export
#' @return
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

#' Modify headers for neo4j
#'
#' <full description>
#'
#' @param x <what param does>
#' @param id1 <what param does>
#' @param id1name <what param does>
#' @param id2 <what param does>
#' @param id2name <what param does>
#'
#' @export
#' @return
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

#' Write out to csv.gz, split to make more manageable files
#'
#' @param obj <what param does>
#' @param splitsize <what param does>
#' @param prefix <what param does>
#' @param id1 <what param does>
#' @param id1name <what param does>
#' @param id2=NULL <what param does>
#' @param id2name=NULL <what param does>
#'
#' @export
#' @return
write_split <- function(obj, splitsize, prefix, id1, id1name, id2=NULL, id2name=NULL)
{
	splitnum <- ceiling(length(obj) / splitsize)
	splits <- split(1:length(obj), 1:splitnum)
	nsplit <- length(splits)
	filenames <- paste0(prefix, 1:nsplit, ".csv.gz")
	lapply(1:length(splits), function(x)
	{
		message(x, " of ", length(splits))
		temp <- bind_rows(obj[splits[[x]]])
		if(is.null(id2))
		{
			temp <- modify_node_headers_for_neo4j(temp, id1, id1name)
		} else {
			temp <- modify_rel_headers_for_neo4j(temp, id1, id1name, id2, id2name)
		}
		gz1 <- gzfile(filenames[x], "w")
		if(x == 1)
		{
			write.table(temp, file=gz1, row.names=FALSE, na="", sep=",")
		} else {
			write.table(temp, file=gz1, row.names=FALSE, na="", col.names=FALSE, sep=",")
		}
		close(gz1)
	})
	return(paste(filenames, collapse=","))
}

#' Wrapper to write out files
#'
#' <full description>
#'
#' @param obj <what param does>
#' @param filename <what param does>
#' @param id1 <what param does>
#' @param id1name <what param does>
#' @param id2=NULL <what param does>
#' @param id2name=NULL <what param does>
#'
#' @export
#' @return
write_simple <- function(obj, filename, id1, id1name, id2=NULL, id2name=NULL)
{
	if(is.null(id2))
	{
		temp <- modify_node_headers_for_neo4j(obj, id1, id1name)
	} else {
		temp <- modify_rel_headers_for_neo4j(obj, id1, id1name, id2, id2name)
	}
	gz1 <- gzfile(filename, "w")
	write.table(temp, file=gz1, row.names=FALSE, na="", sep=",")
	close(gz1)
	return(filename)
}
