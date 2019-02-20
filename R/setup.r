#' Generate random string
#'
#' @param n=1 <what param does>
#'
#' @export
#' @return
random_string <- function(n=1)
{
	a <- do.call(paste0, replicate(2, sample(LETTERS, n, TRUE), FALSE))
	paste0(a, sprintf("%02d", sample(9999, n, TRUE)), sample(LETTERS, n, TRUE))
}


#' Get connection to inventory.sqlite
#'
#' @param path=NULL <what param does>
#'
#' @export
#' @return
getcon <- function(path=NULL)
{
	dbname <- "inventory.sqlite"
	if(is.null(path))
	{
		stopifnot(basename(getwd()) == "mr-eve")
	} else {
		dbname <- file.path(path, dbname)
	}
	DBI::dbConnect(RSQLite::SQLite(), dbname)
}


#' Initial creation of inventory
#'
#' @param path=NULL <what param does>
#'
#' @export
#' @return
setup_inventory <- function(path=NULL)
{
	con <- getcon(NULL)


	"
	CREATE TABLE IF NOT EXISTS slices (
	slice VARCHAR(30) PRIMARY KEY,
	description TEXT NOT NULL,
	method VARCHAR(30) NOT NULL,
	status VARCHAR(30),
	method_version VARCHAR(30),
	creation_date DATETIME,
	trait_a_date DATETIME,
	trait_b_date DATETIME,
	neo4j_date DATETIME
	);
	" -> query1
	out <- dbSendQuery(con, query1, append=TRUE)
	print(out)
	dbClearResult(out)


	"
	CREATE TABLE IF NOT EXISTS inventory (
	objname INTEGER PRIMARY KEY AUTOINCREMENT,
	trait_a VARCHAR(30) NOT NULL,
	trait_b VARCHAR(30) NOT NULL,
	method VARCHAR(30) NOT NULL,
	status VARCHAR(30),
	method_version VARCHAR(30),
	slice VARCHAR(30),
	creation_date DATETIME,
	trait_a_date DATETIME,
	trait_b_date DATETIME,
	neo4j_date DATETIME
	FOREIGN KEY(slice) REFERENCES slices(slice)
	);
	" -> query2
	out <- dbSendQuery(con, query2, append=TRUE)
	print(out)
	dbClearResult(out)
	dbDisconnect(con)
}


#' Check if candidate IDs are ready for analysis
#'
#' @param idlist <what param does>
#' @param datadir <what param does>
#' @param required_files <what param does>
#'
#' @export
#' @return
check_candidate_ids <- function(idlist, datadir, required_files)
{
	# are the necessary data available for each candidate id
	param <- expand.grid(dir=datadir, id=idlist, required_files=required_files, stringsAsFactors=FALSE)
	param$path <- file.path(param$dir, param$id, param$required_files)
	param$present <- file.exists(param$path)
	print(head(param))
	check <- group_by(param, id) %>% summarise(ok = all(present)) %>% filter(ok)
	print(head(check))
	return(check$id)
}


#' Generate viable candidate analysis list
#'
#' @param candidate trait_a, trait_b, method
#'
#' @export
#' @return
initialise_analysis <- function(candidate, description)
{
	message("Checking combinations")
	# candidate = 
	# check if alphabetical
	n <- nrow(candidate)
	candidate <- subset(candidate, trait_a != trait_b)
	candidate <- subset(candidate, !duplicated(paste(trait_a, trait_b, method)))

	candidate <- candidate[apply(candidate, 1, function(x) order(c(x[1], x[2]))[1] == 1), ] %>% arrange(trait_a, trait_b)

	message("Retaining ", nrow(candidate), " of ", n, " candidates")

	# check which are not present

	message("Checking new candidates")
	con <- getcon()
	inventory <- tbl(con, "inventory")

	qu <- paste(candidate$trait_a, candidate$trait_b, candidate$method)

	out <- inventory %>% 
		mutate(key = paste(trait_a, trait_b, method)) %>% 
		filter(key %in% qu) %>% 
		select(key) %>% 
		collect()
	candidate <- candidate[!qu %in% out$key,]
	message(nrow(candidate), " candidates are new")
	message("Creating slice: ", slice)

	slice <- data_frame(
		slice=slice,
		description=description,
		
	)

	lastkey <- inventory %>% summarise(m = max(objname)) %>% collect()
	candidate$objname <- 1:nrow(candidate) + lastkey$m
	candidate$slice <- slice
	candidate$status <- "initialised"
	db_insert_into(con, "inventory", candidate)
	dbReadTable(con, "inventory")
	return(candidate)
}


get_analyses <- function(status)
{
	con <- getcon()
	inventory <- tbl(con, "inventory")
	out <- inventory %>%
		filter(status == status)
	return(out)
}
