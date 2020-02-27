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
   ?title
   ?provider
   ?description
   ?spatial
   ?temporal
   ?modified
   ?page
   ?periodicity
   ?periodicity_abb
   ?start
   ?end
   ?keywords_all
   WHERE {{
     GRAPH ?g {{
       ?dataset_iri a dcat:Dataset .
       ?dataset_iri dcterms:publisher ?publisher .
       ?dataset_iri dcterms:title ?title .
       ?dataset_iri dcterms:description ?description .
       OPTIONAL {{ ?dataset_iri dcterms:identifier ?dataset_id .}}
       OPTIONAL {{ ?dataset_iri dcterms:spatial ?spatial .}}
       OPTIONAL {{ ?dataset_iri foaf:page ?page.}}
       OPTIONAL {{ ?dataset_iri dcterms:temporal ?temporal .}}
       OPTIONAL {{ ?dataset_iri dcterms:modified ?modified .}}
       OPTIONAL {{ ?dataset_iri dcat:keyword ?keywords_all .}}
       OPTIONAL {{ ?dataset_iri dcterms:accrualPeriodicity ?periodicity .}}
       OPTIONAL {{ ?dataset_iri <https://data.gov.cz/slovník/nkod/accrualPeriodicity> ?periodicity_abb .}}

       ?publisher foaf:name ?provider .

       OPTIONAL {{ ?temporal schema:startDate ?start .}}
       OPTIONAL {{ ?temporal schema:endDate ?end .}}

       VALUES ?publisher {{
         <https://data.gov.cz/zdroj/ovm/00025593> # IRI pro CZSO
         # <https://data.gov.cz/zdroj/ovm/00064581> # IRI pro Prahu
       }}
       FILTER(lang(?provider) = \"cs\")
       FILTER(lang(?keywords_all) = \"cs\")
       FILTER(lang(?title) = \"cs\")
     }}
  }}")

  params = list(`default-graph-uri` = "",
                query = sparqlquery_datasets_byczso,
                # format = "application/sparql-results+json",
                format = "text/csv",
                timeout = 30000,
                debug = "on",
                run = "Run Query")
  usethis::ui_info("Downloading")
  cat_rslt <- httr::GET(sparql_url, query = params,
                        # accept("application/sparql-results+json"),
                        httr::add_headers(c("Accept-Charset" = "utf-8")),
                        httr::accept("text/csv;charset=UTF-8"))

  print(params$query)

  usethis::ui_info("Reading data")
  if(httr::status_code(cat_rslt) > 200) {
    print(httr::http_status(cat_rslt))
    rslt <- httr::content(cat_rslt, as = "text")
  } else
    rslt <- cat_rslt %>% httr::content(as = "text")
    rslt <- readr::read_csv(rslt, col_types = readr::cols(modified = "T"))
    usethis::ui_info("Transforming data")
    rslt <- dplyr::group_by(rslt, dataset_iri) %>%
    dplyr::mutate(keywords = stringr::str_c(keywords_all, collapse = "; ")) %>%
    dplyr::ungroup() %>%
    dplyr::select(-keywords_all) %>%
    dplyr::distinct()
  return(rslt)
}
