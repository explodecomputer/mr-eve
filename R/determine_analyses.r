#' What analyses are to be run?
#'
#' For analysis of an ID in terms of PheWAS, just exposure or just outcome is straightforward. However, to either create or update everything-versus-everything we need to make sure we are not duplicating analyses across parallel processes. Strategy is to always just to exposure, because all other ids will perform the outcome analyses. However, when updating an existing graph it gets a bit more complicated - need to also make sure that both exposure and outcome analyses for new ID's are being done without duplicating analysis of old ID's
#'
#' @param id target ID being performed by this node
#' @param idlist List of IDs in dataset
#' @param newidlist Default = NULL. If this is updating an existing analysis then need to use idlist for OLD ids, and newidlist for NEW ids
#' @param what="eve" Can be "phewas", "exposure", "outcome", "eve"
#'
#' @export
#' @return data frame
determine_analyses <- function(id, idlist, newidlist=NULL, what="eve")
{
	idlist <- unique(idlist)
	newidlist <- unique(newidlist)

	if(what == "phewas")
	{
		if(!is.null(newidlist))
		{
			idlist <- unique(c(idlist, newidlist))
		}
		idlist <- idlist[!idlist %in% id]
		param <- bind_rows(
			tibble(exposure=id, outcome=idlist),
			tibble(exposure=idlist, outcome=id)
		)
	}

	if(what == "exposure")
	{
		if(!is.null(newidlist))
		{
			idlist <- unique(c(idlist, newidlist))
		}
		idlist <- idlist[!idlist %in% id]
		param <- tibble(exposure=id, outcome=idlist)
	}

	if(what == "outcome")
	{
		if(!is.null(newidlist))
		{
			idlist <- unique(c(idlist, newidlist))
		}
		idlist <- idlist[!idlist %in% id]
		param <- tibble(exposure=idlist, outcome=id)
	}


	if(what == "eve")
	{
		if(!is.null(newidlist))
		{
			idlist <- idlist[!idlist %in% id]
			newidlist <- newidlist[!newidlist %in% id]
			param <- bind_rows(
				tibble(exposure=id, outcome=idlist),
				tibble(exposure=idlist, outcome=id),
				tibble(exposure=id, outcome=newidlist)
			)
		} else {
			idlist <- idlist[!idlist %in% id]
			param <- bind_rows(
				tibble(exposure=id, outcome=idlist)
			)
		}
	}
	param$id <- paste0(param$exposure, ".", param$outcome)
	return(param)
}
