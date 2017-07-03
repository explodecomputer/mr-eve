library(RNeo4j)
library(shiny)
library(shinydashboard)


graph <- startGraph("http://shark.epi.bris.ac.uk:7474/db/data", username="neo4j", password="123qwe")


browser_url <- "http://shark.epi.bris.ac.uk:7474/browser/"

# a <- getLabeledNodes(graph, "trait") # this is so slow
# b <- getNodes(graph, "match(n:trait) return n")
# nodes <- sapply(a, function(x) x$name)
nodes <- cypher(graph, "match (n:trait) return n.name")$n.name
snps <- cypher(graph, "match(n:snp) return n.name")$n.name
consortia <- cypher(graph, "match (n:trait) return n.consortium")$n.consortium
mrest <- cypher(graph, "match (n)-[r:MRB]-(m) return count(r) as count")$count


load("outcome_nodes.rdata")
outcome_nodes <- iconv(outcome_nodes$trait, sub='')

dashboardPage(

	dashboardHeader(title="MR-EvE"),

	dashboardSidebar(
		sidebarMenu(
			menuItem("About", tabName = "about", icon=icon("smile-o")),
			menuItem("Basic lookup", tabName = "basic", icon=icon("cogs")),
			menuItem("Trait scan", tabName = "trait", icon=icon("cogs"))
		)
	),

	dashboardBody(
		tabItems(
			tabItem(tabName = "about",
				column(6,
					box(title="MR of everything vs everything", width = 12,
						p("This is a repository of Mendelian randomisation estimates that have been generated using the GWAS summary data in the MR-Base database. It can be used to quickly browse specific phenotypes or lookup specific causal hypotheses."),
						p("You can find out more about MR-Base at ", tags$a("http://mrbase.org", "http://www.mrbase.org")),
						p("Important: Mendelian randomization is not a panacea for causal inference. Methodology is still required to reduce sensitivity to violations of assumptions, and to incorporate information about the biological feasibility of causal associations.")
					),
					box(width=12,
						p(tags$strong("Alpha phase release: "), "strictly experimental"),
						p(tags$strong("Last update: "), "3rd July 2017")
					)
				),
				column(6,
					infoBox(width=12, "Phenotypes", length(nodes), icon=icon("database")),
					infoBox(width=12, "MR estimates", mrest, icon = icon("random")),
					infoBox(width=12, "Instrumental variables", length(snps), icon=icon("database")),
					infoBox(width=12, "MR methods", "29", icon=icon("cogs")),
					infoBox(width=12, "GWAS consortia", length(unique(consortia)), icon=icon("globe"))
				)
			),
			tabItem(tabName = "basic",
				fluidRow(
				box(title="Info", width=4,
					p("Lookup the pre-calculated MR estimates for specific exposure and outcome phenotypes"),
					p("MR has been performed using a range of methods. If the exposure has only a single instrument then the Wald ratio is used. If the exposure has 1-5 instruments then the IVW fixed effects method is used. Otherwise, all mean, median and mode based estimaters are applied, along with the mixture of experts analysis that returns the result predicted to be most reliable.")
				),
				box(width=4,
				selectInput("basic_exposure", "Exposure", 
				c("All phenotypes"="", 
				structure(unique(as.character(nodes)), names=unique(as.character(nodes)))), 
				multiple=FALSE
				),
				htmlOutput("basic_exposure_info")
				),

				box(width=4,
				selectInput("basic_outcome", "Outcome", 
				c("All phenotypes"="", 
				structure(unique(as.character(outcome_nodes)), names=unique(as.character(outcome_nodes)))), 
				multiple=FALSE
				),
				htmlOutput("basic_outcome_info"))
				),
				fluidRow(
					box(width = 12,
						p("Copy and paste the following cypher query into the Neo4j browser window to visualise the result: ", tags$a("http://shark.epi.bris.ac.uk:7474/browser/", href="http://shark.epi.bris.ac.uk:7474/browser/")),
						textOutput("basic_query")
					)
				),

				fluidRow(
					box(width=12,
					dataTableOutput('basic_table')
					)
				)
			),

			tabItem(tabName = "trait",
				fluidRow(
				box(title="Info", width=4,
					p("Lookup the pre-calculated MR estimates for a specific phenotype's relationships with all other available phenotypes."),
					p("MR has been performed using a range of methods. If the exposure has only a single instrument then the Wald ratio is used. If the exposure has 1-5 instruments then the IVW fixed effects method is used. Otherwise the mixture of experts analysis that returns the result predicted to be most reliable amongst the mean, mode and median based estimators is displayed for each relationship.")
				),
				box(width=4,
				selectInput("trait_trait", "Phenotype", 
				c("All phenotypes"="", 
				structure(unique(as.character(nodes)), names=unique(as.character(nodes)))), 
				multiple=FALSE
				),
				htmlOutput("trait_trait_info"))
				),
				fluidRow(
					box(width = 12,
						p("Copy and paste the following cypher query into the Neo4j browser window to visualise the result: ", tags$a("http://shark.epi.bris.ac.uk:7474/browser/", href="http://shark.epi.bris.ac.uk:7474/browser/")),
						textOutput("trait_query")
					)
				),

				fluidRow(
					box(width=12,
					dataTableOutput('trait_table')
					)
				)
			)
		)
	)
)

