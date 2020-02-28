
#' Get catalogue of open CZSO datasets
#'
#' Retrieves a list of all CZSO's open datasets available from the Czech Open data catalogue.
#'
#' Use the dataset_id column as an argument to `get_czso_table()`.
#'
#' @return a data frame with details on all CZSO datasets available in the Czech National Open Data Catalogue.
#' @export
#' @family Core workflow
#' @examples
#' \dontrun{
#' get_czso_catalogue()
#' }
get_czso_catalogue <- function() {

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
       OPTIONAL {{ ?dataset_iri <https://data.gov.cz/slovn\\u00edk/nkod/accrualPeriodicity> ?periodicity_abb .}}

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
  }}") %>% stringi::stri_unescape_unicode()

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
                        httr::user_agent(ua_string),
                        httr::add_headers(c("Accept-Charset" = "utf-8")),
                        httr::accept("text/csv;charset=UTF-8"))

  # print(params$query)

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

#' Deprecated: Retrieve and read dataset from CZSO
#'
#' Deprecated, use `get_czso_catalogue()` instead.
#'
#' @inheritParams get_czso_catalogue
#'
#' @return a tibble
#' @examples
#' # see `get_czso_catalogue()`
#' @export
get_catalogue <- function() {
  .Deprecated("get_czso_catalogue")
  get_czso_catalogue()
}

get_czso_dataset_metadata <- function(dataset_id) {
  url <- paste0("https://vdb.czso.cz/pll/eweb/package_show?id=", dataset_id)
  mtdt_c <- httr::GET(url,
            httr::user_agent(ua_string)) %>%
    httr::content(as = "text")
  mtdt <- jsonlite::fromJSON(mtdt_c)[["result"]]
  return(mtdt)
}

get_czso_resources <- function(dataset_id) {
  mtdt <- get_czso_dataset_metadata(dataset_id)
  return(mtdt$result$resources)
}

get_czso_resource_pointer <- function(dataset_id, resource_num = 1) {
  rsrc <- get_czso_resources(dataset_id)[resource_num,] %>%
    dplyr::select(url, format, meta_link = describedBy, meta_format = describedByType)
  return(rsrc)
}

#' Retrieve and read dataset from CZSO
#'
#' Downloads and reads dataset identified by `dataset_id`. Unzips if necessary, but only loads CSV files, otherwise returns the path to the downloaded file.
#'
#' ## Nota bene
#'
#' Do not use this for harvesting datasets from CZSO en masse.
#'
#' @param dataset_id a character. Found in the czso_id column of data frame returned by `get_catalogue()`.
#' @param resource_num integer. Order of resource in resource list for the given dataset. Defaults to 1, the normal value for CZSO datasets.
#' @param force_redownload integer. Whether to redownload data source file even if already cached. Defaults to FALSE.
#'
#' @return a tibble
#' @export
#' @family Core workflow
#' @examples
#' \dontrun{
#' get_czso_table("110080")
#' }
get_czso_table <- function(dataset_id, resource_num = 1, force_redownload = F) {
  ptr <- get_czso_resource_pointer(dataset_id)
  url <- ptr$url
  type <- ptr$format
  ext <- tools::file_ext(url)
  td <- paste(tempdir(), "czso", dataset_id, sep = "/")
  dir.create(td, showWarnings = F, recursive = T)
  dfile <- paste0(td, "/ds_", dataset_id, ".", ext)
  if(file.exists(dfile) & !force_redownload) {
    message(stringr::str_glue("File already in {td}, not downloading. Set `force_redownload` to TRUE if needed."))
  } else {
    utils::download.file(url, dfile, headers = ua_header)
  }

  # print(dfile)

  if(type == "text/csv") {
    action <- "read"
  } else if(type == "application/zip") {
    utils::unzip(dfile, exdir = td)
    flist <- list.files(td, pattern = "(CSV|csv)$")
    if((length(flist) == 1) & (tools::file_ext(flist[1]) %in% c("CSV", "csv"))) {
      action <- "read"
    } else if (length < 1) {
      action <- "listmore"
    } else {
      dfile <- flist[1]
      action <- "listone"
    }
  } else {
    action <- "listone"
  }
  switch (action,
          read = {
            guessed_enc <- readr::guess_encoding(dfile)[[1,1]]
            if(guessed_enc == "windows-1252") guessed_enc <- "windows-1250"
            dt <- suppressWarnings(suppressMessages(readr::read_csv(dfile, col_types = readr::cols(.default = "c",
                                                                                                   rok = "i",
                                                                                                   casref_do = "T",
                                                                                                   ctvrtleti = "i",
                                                                                                   hodnota = "d"),
                                                                 locale = readr::locale(encoding = guessed_enc))))
            rtrn <- dt
          },
          listone = {
            message(paste0("Unable to read this kind of file (",  type, ") automatically. It is saved in ", dfile, "."))
            rtrn <- dfile
          },
          listmore = {
            message(paste0("Multiple files in archive. They are saved in ", td))
            rtrn <- flist

          }
  )
  return(rtrn)
}


#' Deprecated: Retrieve and read dataset from CZSO
#'
#' Deprecated, use `get_czso_table()` instead.
#'
#' @inheritParams get_czso_table
#'
#' @return a tibble
#' @examples
#' # see `get_czso_table()`
#' @export
get_table <- function(dataset_id, resource_num = 1, force_redownload = F) {
  .Deprecated("get_czso_table")
  get_czso_table(dataset_id = dataset_id,
                 resource_num = resource_num,
                 force_redownload = force_redownload)
}


#' Get CZSO table schema
#'
#' Retrieves and parses the schema for the table identified by dataset_id and resource_num.
#'
#' @param dataset_id Dataset ID
#' @param resource_num Resource number, typically 1 in CZSO (the default)
#'
#' @return a tibble with a description of the columns in the table.
#' @examples
#' get_czso_table_schema("110080")
#' @export
#' @family Additional tools
get_czso_table_schema <- function(dataset_id, resource_num = 1) {
  urls <- get_czso_resource_pointer(dataset_id, resource_num)
  schema_url <- urls$meta_link
  schema_type <- urls$meta_format
  if(schema_type == "application/json") {
    suppressMessages(suppressWarnings(schema_result <- httr::GET(schema_url, httr::user_agent(ua_string)) %>%
      httr::content(as = "text")))
    ds <- suppressMessages(suppressWarnings(jsonlite::fromJSON(schema_result)[["tableSchema"]][["columns"]]))
    rslt <- tibble::as_tibble(ds)
  } else {
    usethis::ui_warn("Cannot parse this type of file type. You can get it yourself from {schema_url}")
    rslt <- schema_url
  }
  return(rslt)
}


#' Get documentation for CZSO dataset
#'
#' Retrieves the URL/downloads the file containing the documentation of the dataset, in the required format.
#'
#' @param dataset_id Dataset ID
#' @param action Whether to `return` URL (the default), `download` the file, or `open` the URL in the default web browser.
#' @param destfile Where to save the file. Only used if if `action = download`.
#' @param format What file format to access: `html` (the default), `pdf`, or `word`.
#'
#' @return if `action = download`, the path to the downloaded file; file URL otherwise.
#' @examples
#' get_czso_dataset_doc("110080")
#' @export
#' @family Additional tools
get_czso_dataset_doc <- function(dataset_id,  action = c("return", "open", "download"), destfile = NULL, format = c("html", "pdf", "word")) {
  metadata <- get_czso_dataset_metadata(dataset_id)
  frmt <- match.arg(format)
  url_orig <- metadata$schema
  doc_url <- switch (frmt,
    html = url_orig,
    word = stringr::str_replace(url_orig, "\\.html?", ".docx"),
    pdf = stringr::str_replace(url_orig, "\\.html?", ".pdf")
  )
  act <- match.arg(action)
  if(is.null(destfile)) {dest <- basename(doc_url)} else {dest <- destfile}
  switch(act,
         open = {
           usethis::ui_done("Opening {doc_url} in browser")
           utils::browseURL(doc_url)},
         download = {utils::download.file(doc_url, destfile = dest, headers = ua_header, quiet = T)
           usethis::ui_done("Downloaded {doc_url} to {dest}")})
  if(act == "download") rslt <- dest else rslt <- doc_url
}
