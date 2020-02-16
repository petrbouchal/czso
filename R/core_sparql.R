get_czso_catalogue_s <- function() {

  sparql_url <- "https://data.gov.cz/sparql"

  sparqlquery_datasets_byczso <- stringr::str_glue(
    "PREFIX foaf: <http://xmlns.com/foaf/0.1/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
   PREFIX dcat: <http://www.w3.org/ns/dcat#>
   PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

   SELECT ?dataset_iri
   ?dataset_id
   ?title ?provider ?description
   ?spatial
   ?temporal
   ?modified
   ?page
   ?periodicity
   ?periodicity_abb
   WHERE {{
     GRAPH ?g {{
       ?dataset_iri a dcat:Dataset .
       ?dataset_iri dcterms:title ?title .
       ?dataset_iri dcterms:description ?description .
       ?dataset_iri dcterms:publisher ?publisher .
       OPTIONAL {{ ?dataset_iri dcterms:identifier ?dataset_id .}}
       OPTIONAL {{ ?dataset_iri dcterms:spatial ?spatial .}}
       OPTIONAL {{ ?dataset_iri foaf:page ?page.}}
       OPTIONAL {{ ?dataset_iri dcterms:temporal ?temporal .}}
       OPTIONAL {{ ?dataset_iri dcterms:modified ?modified .}}
       OPTIONAL {{ ?dataset_iri dcterms:accrualPeriodicity ?periodicity .}}
       OPTIONAL {{ ?dataset_iri <https://data.gov.cz/slovník/nkod/accrualPeriodicity> ?periodicity_abb .}}

       ?publisher foaf:name ?provider .

       VALUES ?publisher {{
         <https://data.gov.cz/zdroj/ovm/00025593> # IRI pro CZSO
       }}
       FILTER(lang(?provider) = \"cs\")
       FILTER(lang(?title) = \"cs\")
     }}
  }}")

  params = list(`default-graph-uri` = "",
                query = sparqlquery_datasets_byczso,
                # format = "application/sparql-results+json",
                format = "text/csv",
                timeout = 0,
                debug = "on",
                run = "Run Query")

  cat_rslt <- httr::GET(sparql_url, query = params,
                        # accept("application/sparql-results+json"),
                        httr::add_headers(c("Accept-Charset" = "utf-8")),
                        httr::accept("text/csv;charset=UTF-8"))

  print(params$query)

  if(httr::status_code(cat_rslt) > 200) {
    rslt <- httr::content(cat_rslt)
  } else
    rslt <- cat_rslt %>% httr::content(as = "text") %>%
    readr::read_csv()
  return(rslt)
}
