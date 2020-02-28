library(httr)
library(jsonlite)
library(stringr)
library(readr)

url <- "https://data.gov.cz/sparql"

# Všechny datasety jednoho providera, podle IRI ---------------------------

sparqlquery_datasets_provider <- str_glue(
  "PREFIX foaf: <http://xmlns.com/foaf/0.1/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
   PREFIX dcat: <http://www.w3.org/ns/dcat#>
   PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

   SELECT ?dataset_iri ?title ?provider ?description ?spatial ?issued ?periodicity WHERE {{
     GRAPH ?g {{
       ?dataset_iri a dcat:Dataset ;
          dcterms:title ?title ;
          dcterms:spatial ?spatial ;
          dcterms:issued ?issued ;
          dcterms:accrualPeriodicity ?periodicity ;
          dcterms:description ?description ;
         	dcterms:publisher ?publisher .

       ?publisher foaf:name ?provider .

       VALUES ?publisher {{
         <https://data.gov.cz/zdroj/ovm/00025593> # IRI pro CZSO
       }}
       FILTER(lang(?provider) = \"cs\")
       FILTER(lang(?title) = \"cs\")
     }}
}}")

# Všechny datasety jednoho providera, podle názvu (přesně) ----------------

sparqlquery_datasets_provider_name <- str_glue(
  "PREFIX foaf: <http://xmlns.com/foaf/0.1/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
   PREFIX dcat: <http://www.w3.org/ns/dcat#>
   PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

   SELECT ?dataset ?název ?provider ?popis WHERE {{
     GRAPH ?g {{
       ?dataset a dcat:Dataset ;
          dcterms:title ?název ;
          dcterms:description ?popis ;
         	dcterms:publisher ?publisher .

       ?publisher foaf:name ?provider .

     }}
       VALUES ?poskytovatel {{
         \"Ministerstvo vnitra\"@cs # IRI pro CZSO
       }}
       FILTER(lang(?poskytovatel) = \"cs\")
       FILTER(lang(?název) = \"cs\")
}}")

params = list(`default-graph-uri` = "",
              query = sparqlquery_datasets_provider,
              # format = "application/sparql-results+json",
              format = "text/csv",
              timeout = 0,
              debug = "on",
              run = "Run Query")

plz <- httr::GET(url, query = params,
                 # accept("application/sparql-results+json"),
                 add_headers(c("Accept-Charset" = "utf-8")),
                 accept("text/csv;charset=UTF-8")
)

plz %>% stop_for_status()

plz$request$headers

plz$headers$`content-type`
plzd <- plz %>% content(as = "text")

plzd <- plz %>% content(as = "text") %>%
  read_csv()

plzd$results$bindings %>% names()
plzd$results$bindings %>% head()

# Všechny distribuce jednoho datasetu, podle IRI --------------------------

sparqlquery_distribs_dataset <- str_glue(
  "PREFIX foaf: <http://xmlns.com/foaf/0.1/>
   PREFIX dcterms: <http://purl.org/dc/terms/>
   PREFIX dcat: <http://www.w3.org/ns/dcat#>
   PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>



   SELECT ?url, ?format WHERE {{
     GRAPH ?g {{
       ?dataset a dcat:Dataset ;
           dcat:distribution ?distribution .

       ?distribution dcat:downloadURL ?url .
       ?distribution dct:format ?format .

       VALUES ?dataset {{
         <https://data.gov.cz/zdroj/datové-sady/https---opendata.plzen.eu-api-3-action-package_show-id-gis-ostatni-wc> # IRI pro dataset
       }}
     }}
  }}"
)

url <- "https://data.gov.cz/sparql"
params_ds = list(`default-graph-uri` = "",
                 query = sparqlquery_distribs_dataset,
                 # format = "application/sparql-results+json",
                 format = "text/csv",
                 timeout = 0,
                 debug = "on",
                 run = "Run Query")

ds <- httr::GET(url, query = params_ds,
                # accept("application/sparql-results+json"),
                config = add_headers(c("Accept-charset" = "utf-8"))
) %>%
  stop_for_status()

# ds$headers$`content-type`
# ds$status_code
#
# dst <- ds %>% content(as = "text") %>%
#   fromJSON()

dst <- ds %>%
  content(as = "text") %>%
  read_csv()

ss <- GET("https://data.gov.cz/zdroj/lok%C3%A1ln%C3%AD-katalogy/CSttstckyU/214608232", accept_json()) %>%
  content()
tt <- ss[[1]][[6]]
s <- map_chr(tt, 2)

# Všichni providers -------------------------------------------------------

sparqlquery_providers <- "PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dcterms: <http://p <- .org/dc/terms/>
PREFIX dcat: <http://www.w3.org/ns/dcat#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?poskytovatel ?publisher WHERE {
  GRAPH ?g {

    ?publisher foaf:name ?poskytovatel .

    FILTER(lang(?poskytovatel) = \"cs\")
    FILTER(?poskytovatel = \"Ministerstvo vnitra\"@cs)
  }

}"

params_prv = list(`default-graph-uri` = "",
                  query = sparqlquery_providers,
                  # format = "application/sparql-results+json",
                  format = "text/csv",
                  timeout = 0,
                  debug = "on",
                  run = "Run Query")

prv <- httr::GET(url, query = params_prv,
                 # accept("application/sparql-results+json"),
                 config = add_headers(c("Accept-charset" = "utf-8"))
) %>%
  stop_for_status()

# ds$headers$`content-type`
# ds$status_code
#
# dst <- ds %>% content(as = "text") %>%
#   fromJSON()

prvt <- prv %>%
  content(as = "text") %>%
  read_csv()



