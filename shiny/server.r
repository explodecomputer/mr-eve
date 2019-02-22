library(RNeo4j)
library(shiny)

escape_quote <- function(text)
{
	gsub("'", "\\\\'", text)
}


get_query_trait <- function(graph, trait)
{
	query <- paste0("match 
		(n:TRAIT {trait: '", escape_quote(trait), "'})
		-[r:MR]-
		(m:TRAIT)

		return n,r,m order by r.P limit 200"
	)
	return(query)
}

get_query_exposure_outcome <- function(graph, exposure, outcome)
{
	query <- paste0("match 
		(g:GENE)-[rg:ANNOTATION]->(s:VARIANT)-[rs:INSTRUMENT]->(n:TRAIT {trait: '", escape_quote(exposure), "'})
		-[r:MR]->
		(m:TRAIT {trait: '", escape_quote(outcome), "'}) 
		return n,r,m,rg,g,s,rs"
	)
	return(query)
}

get_table_exposure_outcome <- function(graph, exposure, outcome)
{
	query <- paste0("match 
		(n:TRAIT {trait: '", escape_quote(exposure), "'})
		-[r:MR]->
		(m:TRAIT {trait: '", escape_quote(outcome), "'}) 
		return
		r.method+' - '+r.selection as Method, 
		r.nsnp as nsnp,
		r.b as Estimate, 
		r.se as SE,
		r.ci_low as CI_low,
		r.ci_upp as CI_upp,
		r.pval as P"
	)
	return(cypher(graph, query))
}

# get_table_exposure_outcome(graph, "Body mass index", "Parkinson's disease")


get_trait_scan <- function(graph, trait)
{
	query <- paste0("match 
		(n:TRAIT)
		-[r:MRMOE]->
		(m:TRAIT)

		where (n.trait = '", escape_quote(trait), "' and m.trait <> '", escape_quote(trait), "') or (m.trait = '", escape_quote(trait), "' and n.trait <> '", escape_quote(trait), "')

		return

		n.trait as Exposure,
		m.trait as Outcome,
		r.method+' - '+r.selection as Method, 
		r.nsnp as nsnp,
		r.b as Estimate, 
		r.se as SE,
		r.ci_low as CI_low,
		r.ci_upp as CI_upp,
		r.pval as P
		order by P"
	)
	o <- cypher(graph, query)
	o$FDR <- p.adjust(o$P, "fdr")
	return(o)
}

get_trait_info <- function(graph, trait)
{
	if(is.null(trait)) return(HTML(""))

	query <- paste0("match
		(n:TRAIT {trait: '", escape_quote(trait), "'})
		return
		n.trait as name,
		n.category as category,
		n.subcategory as subcategory,
		n.EFO as EFO,
		n.EFO_id as EFO_id,
		n.ncase as ncase,
		n.ncontrol as ncontrol,
		n.sample_size as sample_size,
		n.author as author,
		n.consortium as consortium,
		n.pmid as pmid,
		n.traitId as traitId
	")
	o <- cypher(graph, query)

	return(HTML(
		paste0(
		"<strong>name:</strong> ", o$name[1], "<br/>",
		"<strong>category:</strong> ", o$category[1], "<br/>",
		"<strong>subcategory:</strong> ", o$subcategory[1], "<br/>",
		"<strong>EFO:</strong> ", o$EFO[1], "<br/>",
		"<strong>EFO_id:</strong> ", o$EFO_id[1], "<br/>",
		"<strong>ncase:</strong> ", o$ncase[1], "<br/>",
		"<strong>ncontrol:</strong> ", o$ncontrol[1], "<br/>",
		"<strong>sample_size:</strong> ", o$sample_size[1], "<br/>",
		"<strong>author:</strong> ", o$author[1], "<br/>",
		"<strong>consortium:</strong> ", o$consortium[1], "<br/>",
		"<strong>pmid:</strong> ", o$pmid[1], "<br/>",
		"<strong>traitId:</strong> ", o$traitId[1], "<br/>"
		)
	))
}

# get_trait_info(graph, "Body mass index")



server <- function(input, output) { 

graph <- startGraph("http://shark.epi.bris.ac.uk:8474/db/data", username="neo4j", password="123qwe")

output$basic_exposure_info <- renderUI(get_trait_info(graph, input$basic_exposure))
output$basic_outcome_info <- renderUI(get_trait_info(graph, input$basic_outcome))

output$basic_query <- renderText(get_query_exposure_outcome(graph, input$basic_exposure, input$basic_outcome))

output$basic_table <- renderDataTable({
	# input$basic_submit
	return(get_table_exposure_outcome(graph, input$basic_exposure, input$basic_outcome))
})

output$trait_trait_info <- renderUI(get_trait_info(graph, input$trait_trait))

output$trait_query <- renderText(get_query_trait(graph, input$trait_trait))

output$trait_table <- renderDataTable(
	get_trait_scan(graph, input$trait_trait)
)



}
