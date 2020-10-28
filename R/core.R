
#' Get catalogue of open CZSO datasets
#'
#' Retrieves a list of all CZSO's open datasets available from the Czech Open data catalogue.
#'
#' Use the dataset_id column as an argument to `get_czso_table()`.
#'
#' @return a data frame with details on all CZSO datasets available in the Czech National Open Data Catalogue.
#' The columns are fairly well described by their names, except:
#'
#' - some columns contain IRIs instead of human readable text; still you can deduce the content from the IRI.
#' - the `spatial` columns contains an IRI ending in the pattern {unit_type}/{unit_code}.
#' The unit_type denotes what unit the data covers (scope/domain not granularity) and the second identifies the unit covered.
#' The unit_type will usually be `"stat"` for "state" and the unit_code will be 1.
#' The unit_type can also be `"KR"` for region or `"OB"` for municipality, or `"OK"` for district.
#' In that case, the unit_code will be a code of that unit.
#' - `page` points to the documentation, i.e. methodology notes for the dataset.
#'
#' @export
#' @family Core workflow
#' @examples
#' \donttest{
#' czso_get_catalogue()
#' }
czso_get_catalogue <- function() {

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
  if(!curl::has_internet()) usethis::ui_stop(c("No internet connection. Cannot continue. Retry when connected."))
  usethis::ui_info("Reading data from data.gov.cz")
  cat_rslt <- httr::GET(sparql_url, query = params,
                        # accept("application/sparql-results+json"),
                        httr::user_agent(ua_string),
                        httr::add_headers(c("Accept-Charset" = "utf-8")),
                        httr::accept("text/csv;charset=UTF-8")) %>%
    httr::stop_for_status()

  # print(params$query)

  if(httr::status_code(cat_rslt) > 200) {
    print(httr::http_status(cat_rslt))
    rslt <- httr::content(cat_rslt, as = "text")
  } else
    rslt <- cat_rslt %>% httr::content(as = "text")
  rslt <- readr::read_csv(rslt, col_types = readr::cols(modified = "T"))
  usethis::ui_done("Done downloading and reading data")
  usethis::ui_info("Transforming data")
  rslt <- dplyr::group_by(rslt, .data$dataset_iri) %>%
    dplyr::mutate(keywords = stringr::str_c(.data$keywords_all, collapse = "; ")) %>%
    dplyr::ungroup() %>%
    dplyr::select(-.data$keywords_all) %>%
    dplyr::distinct()
  return(rslt)
}

#' Deprecated: use `czso_get_catalogue()` instead
#'
#' \lifecycle{deprecated}
#'
#' @return a tibble
#' @examples
#' # see `czso_get_catalogue()`
#' @export
get_catalogue <- function() {
  lifecycle::deprecate_warn("0.2.0", "czso::get_catalogue()", "czso_get_catalogue()")
  czso_get_catalogue()
}

#' Deprecated, use `czso_get_catalogue()` instead.
#'
#' \lifecycle{deprecated}
#'
#' @return a tibble
#' @examples
#' # see `czso_get_catalogue()`
#' @export
get_czso_catalogue <- function() {
  lifecycle::deprecate_warn("0.2.1", "czso::get_czso_catalogue()", "czso_get_catalogue()")
  czso_get_catalogue()
}


#' Get dataset metadata
#'
#' Get metadata from CZSO API, which can be somewhat more detailed/readable than
#' what is provided in the dataset's entry in the output of `czso_get_dataset()`.
#'
#' As far as I can tell there is no way to get the metadata in English, though
#' some key datasets, such as codelists, do have English-languge documentation.
#' See `czso_get_table()` for how to access English-language codelists (registers).
#'
#' @param dataset_id Dataset ID
#'
#' @return a list with elements named in English, where the names are mostly self-explanatory.
#' So are the contents where these are dates; title, description, notes and tags only exist in Czech as far as I know.
#' Some fields merit explanation:
#'
#' - `resources`: a list of files available to download in this dataset
#' - `frequency`: see https://project-open-data.cio.gov/iso8601_guidance/ for a key
#' - `ruian_type`: what type of spatial unit the data covers (spatial domain/extent/scope, not granularity).
#' `ST` means "state" (this is almost always the case), `"KR"` means region (kraj),
#' `"OK"` district (okres), `"OB"` municipality (obec);
#' `"RS"` cohesion region (region soudržnosti, larger than region)
#' - `ruian_code`: the code of the unit the data covers as per the RUIAN taxonomy
#' - `schema` points to documentation while `describedBy` points to the technical schema in JSON or XML.
#'
#'
#' @examples
#' \donttest{
#' czso_get_dataset_metadata("110080")
#' }
#' @export
#' @family Additional tools
czso_get_dataset_metadata <- function(dataset_id) {
  if(!curl::has_internet()) usethis::ui_stop(c("No internet connection. Cannot continue. Retry when connected."))
  url <- paste0("https://vdb.czso.cz/pll/eweb/package_show?id=", dataset_id)
  mtdt_c <- httr::GET(url,
                      httr::user_agent(ua_string)) %>%
    httr::stop_for_status() %>%
    httr::content(as = "text")
  mtdt <- jsonlite::fromJSON(mtdt_c)[["result"]]
  if(is.null(mtdt)) usethis::ui_stop("No dataset found with this ID.")
  return(mtdt)
}

#' Deprecated, use `czso_get_catalogue()` instead.
#'
#' \lifecycle{deprecated}
#'
#' @inheritParams czso_get_dataset_metadata
#'
#' @return a list
#' @export
#' @family Additional tools
get_czso_dataset_metadata <- function(dataset_id) {
  lifecycle::deprecate_warn("0.2.1", "czso::get_czso_dataset_metadata()",
                            "czso_get_dataset_metadata()")
  czso_get_dataset_metadata(dataset_id = dataset_id)
}
get_czso_resources <- function(dataset_id) {
  mtdt <- czso_get_dataset_metadata(dataset_id)
  return(mtdt$resources)
}


# Internal utilities ------------------------------------------------------

read_czso_csv <- function(dfile) {
  guessed_enc <- readr::guess_encoding(dfile)
  guessed_enc <- ifelse(length(guessed_enc$encoding) == 0 || guessed_enc$encoding[[1]] == "windows-1252",
                        "windows-1250", # a sensible default, considering...
                        guessed_enc$encoding[1])
  dt <- suppressWarnings(suppressMessages(readr::read_csv(dfile, col_types = readr::cols(.default = "c",
                                                                                         rok = "i",
                                                                                         ADMPLOD = readr::col_date("%d.%m.%Y"),
                                                                                         ADMNEPO = readr::col_date("%d.%m.%Y"),
                                                                                         casref_od = "T",
                                                                                         casref_do = "T",
                                                                                         obdobiod = "T",
                                                                                         obdobido = "T",
                                                                                         bazobdobiod = "T",
                                                                                         bazobdobido = "T",
                                                                                         ctvrtleti = "i",
                                                                                         hodnota = "d"),
                                                          locale = readr::locale(encoding = guessed_enc))))
}

download_if_needed <- function(url, dfile, force_redownload) {
  if(file.exists(dfile) & !force_redownload) {
    usethis::ui_info(c("File already in {usethis::ui_path(dirname(dfile))}, not downloading.",
                       "Set {usethis::ui_code('force_redownload = TRUE')} if needed."))
  } else {
    curl_handle <- curl::new_handle() %>%
      curl::handle_setheaders(.list = ua_header)
    curl::curl_download(url, dfile, handle = curl_handle)
  }
}

get_dl_path <- function(dataset_id, dir = tempdir(), ext) {
  td <- file.path(dir, dataset_id)
  dir.create(td, showWarnings = FALSE, recursive = TRUE)
  dfile <- paste0(td, "/ds_", dataset_id, ".", ext)
  return(dfile)
}

get_czso_resource_pointer <- function(dataset_id, resource_num = 1) {
  rsrc <- get_czso_resources(dataset_id)[resource_num,] %>%
    dplyr::select(.data$url, .data$format, meta_link = .data$describedBy, meta_format = .data$describedByType)
  return(rsrc)
}


# Key workflow ------------------------------------------------------------



#' Retrieve and read dataset from CZSO
#'
#' Downloads and reads dataset identified by `dataset_id`.
#' Unzips if necessary, but only loads CSV files, otherwise returns the path to the downloaded file.
#' Converts types of columns where known, e.g. value columns to numeric.
#'
#' ## Structure of the output tibble
#'
#' CZSO provides its open data as tidy data, so each row only contains one value
#' in the `hodnota` column and the remaining columns give details on how
#' that value is defined. See "Included columns" below on how these work.
#'
#'
#'
#' ## Data types
#'
#' The schema of the dataset is not yet used, so some columns may be mistyped and are by default returned as character vectors.
#'
#' ## Included columns
#'
#' The range of columns present in the output varies from one dataset to another,
#' so the package does not attempt to provide English-language names for
#' the known subset, as that would result in a jumble of Czenglish.
#'
#' Instead, here is a guide to some of the common column names you will encounter:
#'
#' - `idhod`: a unique ID of the value in the CZSO databse. This does not allow
#' you to link to any other (meta)data as far as I know, but it does provide unique
#' identification should you need it.
#' - `hodnota`: the value.
#' - `stapro_kod`: code of the statistic/indicator/variable as listed.
#' in the SMS UKAZ register (https://www.czso.cz/csu/czso/statistical-variables-indicators);
#' this one has Czech-English documentation - access this by clicking the UK flag top right.
#' You can also get a data table with the definitions, if you search for `"statistické proměnné"` in
#' the `title` field of the catalogue. Last I checked, the ID of this table was `"990124-17"`.
#' - `rok` denotes year as YYYY.
#' - `ctvrtleti` denotes quarter if available.
#'
#' Other metadata will come in the form `{variable}_[txt|cis|kod]`. The `_txt`
#' column holds the Czech text name for the category. The `_cis` column holds the
#' ID of the codelist (register) you need to decode the code in `_kod`.
#' The English codelists are at http://apl.czso.cz/iSMS/en/cislist.jsp,
#' Czech ones at http://apl.czso.cz/iSMS/cs/cislist.jsp.
#' You can find the Czech-language codelists in the catalogue retrieved with
#'  `czso_get_catalogue()`, where their IDs begin with `"cis"` followed by the number; the English ones can also be retrieved from
#'  the link above using a permalink URL.
#'
#'  More conveniently, you can use the `czso_get_codelist()` function to retrieve the codelist.
#'
#'  Units are denoted in a separate column.
#'
#'  A helper on common breakdowns with their associated columns:
#'
#'  - `uzemi`: territory
#'  - `vek`: age
#'  - `pohlavi`: gender
#'
#' `NA`s in "breakdown" columns (e.g. gender or age) denote the total.
#'
#' @note Do not use this for harvesting datasets from CZSO en masse.
#'
#' @param dataset_id a character. Found in the czso_id column of data frame returned by `get_catalogue()`.
#' @param dest_dir character. Directory in which downloaded files will be stored.
#' If left unset, will use the `czso.dest_dir` option if the option is set, and `tempdir()` otherwise. Will be created if it does not exist.
#' @param resource_num integer. Order of resource in resource list for the given dataset. Defaults to 1, the normal value for CZSO datasets.
#' @param force_redownload integer. Whether to redownload data source file even if already cached. Defaults to FALSE.
#'
#' @return a [tibble][tibble::tibble-package], or vector of file paths if file is not CSV or if
#' there are multiple files in the dataset.
#' See Details on the columns contained in the tibble
#' @family Core workflow
#' @examples
#' \donttest{
#' czso_get_table("110080")
#' }
#' @export
czso_get_table <- function(dataset_id, dest_dir = NULL, force_redownload = FALSE, resource_num = 1) {

  if(stringr::str_detect(dataset_id, "^cis")) {
    usethis::ui_info("The dataset you are fetching seems to be a codelist.")
    usethis::ui_todo("Use {usethis::ui_code(x = stringr::str_glue('czso_get_codelist(\"{dataset_id}\")'))} to load it using a dedicated function.")
  }

  ptr <- get_czso_resource_pointer(dataset_id, resource_num = resource_num)
  url <- ptr$url
  type <- ptr$format
  ext <- tools::file_ext(url)
  if(ext == "" | is.null(ext)) ext <- stringr::str_extract(type, "(?<=\\/).*$")

  if(is.null(dest_dir)) dest_dir <- getOption("czso.dest_dir",
                                              default = tempdir())

  dfile <- get_dl_path(dataset_id, dest_dir, ext)

  download_if_needed(url, dfile, force_redownload)

  # print(dfile)

  if(type == "text/csv") {
    action <- "read"
  } else if(type == "application/zip") {
    utils::unzip(dfile, exdir = dirname(dfile))
    flist <- list.files(dirname(dfile), pattern = "(CSV|csv)$")
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
            rtrn <- read_czso_csv(dfile)
            invi <- F
          },
          listone = {
            usethis::ui_info(c("Unable to read this kind of file ({type}) automatically.",
                               "It is saved in {usethis::ui_path(dfile)}."))
            rtrn <- dfile
            invi <- T
          },
          listmore = {
            usethis::ui_info(c("Multiple files in archive.",
                               "They are saved in {usethis::ui_path(dfile)}"))
            rtrn <- flist
            invi <- T

          }
  )
  if(invi) invisible(rtrn) else return(rtrn)
}


#' Deprecated: use `czso_get_table()` instead.
#'
#' \lifecycle{deprecated}.
#'
#' @inheritParams czso_get_table
#'
#' @return a [tibble][tibble::tibble-package]
#' @family Core workflow
#' @examples
#' # see `czso_get_table()`
#' @export
get_table <- function(dataset_id, resource_num = 1, force_redownload = FALSE) {
  lifecycle::deprecate_warn("0.2.0", "czso::get_catalogue()", "czso_get_catalogue()")
  czso_get_table(dataset_id = dataset_id,
                 resource_num = resource_num,
                 force_redownload = force_redownload)
}

#' Get CZSO codelist (registry / číselník)
#'
#' Downloads codelist (registry table) and returns it in a tibble.
#' Codelists are canonical lists of entities, their names and IDs. See Details.
#' Codelists are included in catalogue which can be retrieved using `czso_get_catalogue()`.
#' Their IDs start with `"cis"` followed by a two- to three-digit number.
#'
#' ## Codelists
#'
#' Codelists are canonical registries of entities:
#' things, statistical areas and aggregates, concepts, categorisations.
#' A codelist typically contains IDs and names of all the entities fitting into
#' a certain category.
#'
#' The most commonly used codelists are geographical, e.g. lists of regions or
#' municipalities.
#'
#' In the world of the CZSO, each codelist has a numeric ID of two to four digits.
#' You can pass this number to the function (even as a string), or you can pass the dataset ID found
#' in the catalogue; the latter will have the form of e.g. `"cisNN"`.
#'
#' ### Relationships between codelists ("vazba mezi číselníky")
#'
#' The CZSO data store also holds tables describing relations between codelists.
#' This is especially useful for spatial hierarchies (e.g. which towns belong to which region), or for converting
#'  between categorisations (e.g. two different sets of IDs for regions.)
#'
#' You can pass a vector of two IDs (numeric or character) and if the relational
#' table for these two exists, it will be returned. (If it does not work,
#' try flipping them around). The equivalent dataset ID, as found in the catalogue,
#' is `"cisXXvazYY"`.
#'
#' ## Columns in output
#'
#' For single-codelist files, see below for the most commonly included columns.
#' For relational tables, you will see each column twice, each time with a suffix of 1 or 2.
#'
#' - AKRCIS: codelist abbreviation
#' - KODCIS: codelist ID
#' - CHODNOTA: entity ID
#' - TEXT: entity name
#' - ZKRTEXT: entity name abbreviated
#' - ADMPLOD: valid from
#' - ADMNEPO: invalid after
#' - KOD_RUIAN: for geographical entites, RUIAN code (different master registry run by the geodesists)
#' - CZNUTS: for geographical entities, NUTS code
#'
#' @param codelist_id character or numeric of length 1 or 2; ID of codelist to download. See Details.
#' @param language language, either "cs" (the default) or "en", which is available for some codelists.
#' @param dest_dir character. Directory in which downloaded files will be stored.
#' If left unset, will use the `czso.dest_dir` option if the option is set, and `tempdir()` otherwise. Will be created if it does not exist.
#' @param resource_num integer, order of resource. Only override if you need a different format.
#' @param force_redownload whether to download even if a cached local file is available.
#'
#' @return a [tibble][tibble::tibble-package] All columns except dates kept as character.
#' See Details for the columns.
#' @examples
#' \donttest{
#' czso_get_codelist("cis100")
#'
#' # equivalent
#' czso_get_codelist(100)
#'
#' # get a table of relations between two codelists
#' czso_get_codelist(c(100, 43))
#'
#' # equivalent
#' czso_get_codelist("cis100vaz43")
#' }
#' @export
czso_get_codelist <- function(codelist_id,
                              language = c("cs", "en"),
                              dest_dir = NULL,
                              resource_num = NULL,
                              force_redownload = F) {

  lng <- match.arg(language)

  stopifnot(length(codelist_id) <= 2)

  if(length(codelist_id) == 1) {
    if(is.numeric(codelist_id) | stringr::str_detect(codelist_id,
                                                     "^[0-9]{2,4}$")) {
      codelist_id <- paste0("cis", codelist_id)
    }
  } else if(length(codelist_id) == 2) {
    if(is.numeric(codelist_id) | all(stringr::str_detect(codelist_id,
                                                         "^[0-9]{2,4}$"))) {
      codelist_id <- paste0("cis", codelist_id[1], "vaz", codelist_id[2])
    }
  }

  if(!stringr::str_detect(codelist_id, "^cis")) {
    usethis::ui_info(c("The value you passed to {usethis::ui_field('codelist_id')} does not seem to indicate a codelist.",
                       "This may cause unexpected results."))
  }

  cis_meta <- get_czso_resources(codelist_id)

  cis_url <- cis_meta[cis_meta$format == "text/csv", "url"]

  if(length(cis_url) < 1) {
    # usethis::ui_stop(c("No CSV distribution for this codelist found.",
    #                    "You can download the codelist in the format provided using {ui_code(x = stringr::str_glue('czso_get_table(\"{codelist_id}\")'))} and read it in manually.",
    #                    "Use {ui_code(x = stringr::str_glue('czso_get_dataset_metadata(\"{codelist_id}\")'))} to see which formats are available."))

    if(is.null(resource_num)) resource_num <- 1

    usethis::ui_info("No documented CSV distribution found for this codelist. Using workaround.")

    cis_url <- get_czso_resource_pointer(codelist_id, 1)[["url"]]
    cis_url <- stringr::str_replace(cis_url, "format\\=0$", "format=2&separator=,")
  }

  if(lng == "en") cis_url <- stringr::str_replace(cis_url, "cisjaz=203", "cisjaz=8260")

  if(is.null(dest_dir)) dest_dir <- getOption("czso.dest_dir",
                                              default = tempdir())
  dfile <- get_dl_path(codelist_id, dest_dir, "csv")

  download_if_needed(cis_url, dfile, force_redownload)

  dt <- read_czso_csv(dfile)

  return(dt)
}


# Utilities ---------------------------------------------------------------



#' Get CZSO table schema
#'
#' Retrieves and parses the schema for the table identified by dataset_id and resource_num.
#'
#' Currently only handles JSON schema files for CSV files.
#' If the schema is a different format, an error is returned pointing the user to the URL of the file.
#'
#' @param dataset_id Dataset ID
#' @param resource_num Resource number, typically 1 in CZSO (the default)
#'
#' @return a tibble with a description of the table columns, with the following items:
#' - `name`: the column name.
#' - `titles`: usually the duplicate of `name`
#' - `dc:description`: a Czech-language description of the column
#' - `required`: whether the column is required
#' - `datatatype`: the data type of the column; either "number" or "string"
#'
#' @examples
#' \donttest{
#' czso_get_table_schema("110080")
#' }
#' @export
#' @family Additional tools
czso_get_table_schema <- function(dataset_id, resource_num = 1) {
  urls <- get_czso_resource_pointer(dataset_id, resource_num)
  schema_url <- urls$meta_link
  schema_type <- urls$meta_format
  is_json <- schema_type == "application/json"
  if(is_json) {
    suppressMessages(suppressWarnings(schema_result <- httr::GET(schema_url, httr::user_agent(ua_string)) %>%
      httr::content(as = "text")))
    ds <- suppressMessages(suppressWarnings(jsonlite::fromJSON(schema_result)[["tableSchema"]][["columns"]]))
    rslt <- tibble::as_tibble(ds)
  } else {
    usethis::ui_stop("Cannot parse this type of file type.
                     You can get it yourself from {usethis::ui_path(schema_url)}.")
    rslt <- schema_url
  }
  return(rslt)
}

#' Deprecated: use `czso_get_table_schema()` instead
#'
#' \lifecycle{deprecated}
#'
#' @inheritParams czso_get_table_schema
#'
#' @return a list
#' @export
#' @family Additional tools
get_czso_table_schema <- function(dataset_id, resource_num) {
  lifecycle::deprecate_warn("0.2.1", "czso::get_czso_table_schema()",
                            "czso_get_table_schema()")
  czso_get_table_schema(dataset_id = dataset_id, resource_num = resource_num)
}


#' Get documentation for CZSO dataset
#'
#' Retrieves the URL/downloads the file containing the documentation of the dataset, in the required format.
#'
#' The document to which this functions provides access contains methodological
#' background on the specified dataset and is identified by the `schema` field
#' in the list returned by `czso_get_dataset_metadata()`.
#'
#' @param dataset_id Dataset ID
#' @param action Whether to `return` URL (the default), `download` the file, or `open` the URL in the default web browser.
#' @param destfile Where to save the file. Only used if if `action = download`.
#' @param format What file format to access: `html` (the default), `pdf`, or `word`.
#'
#' @return if `action = download`, the path to the downloaded file; file URL otherwise.
#' @examples
#' \donttest{
#' czso_get_dataset_doc("110080")
#' }
#' @export
#' @family Additional tools
czso_get_dataset_doc <- function(dataset_id,  action = c("return", "open", "download"), destfile = NULL, format = c("html", "pdf", "word")) {
  metadata <- czso_get_dataset_metadata(dataset_id)
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
           usethis::ui_done("Opening {usethis::ui_path(doc_url)} in browser")
           utils::browseURL(doc_url)},
         download = {utils::download.file(doc_url, destfile = dest, headers = ua_header, quiet = TRUE)
           usethis::ui_done("Downloaded {usethis::ui_path(doc_url)} to {usethis::ui_path(dest)}")})
  if(act == "download") rslt <- dest else rslt <- doc_url
  if(act == "return") rslt else invisible(rslt)
}

#' Deprecated: use `czso_get_dataset_doc()` instead
#'
#' \lifecycle{deprecated}
#'
#' @inheritParams czso_get_dataset_doc
#'
#' @return a list
#' @export
#' @family Additional tools
get_czso_dataset_doc <- function(dataset_id,  action = c("return", "open", "download"), destfile = NULL, format = c("html", "pdf", "word")) {
  lifecycle::deprecate_warn("0.2.1", "czso::get_czso_dataset_doc()",
                            "czso_get_dataset_doc()")
  czso_get_dataset_doc(dataset_id = dataset_id, action = action, destfile = destfile, format = format)
}


