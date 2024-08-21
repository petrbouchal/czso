#' Get catalogue of open CZSO datasets
#'
#' Retrieves a list of all CZSO's open datasets available from the Czech Open data catalogue.
#'
#' Pass the string in the `dataset_id` column to `get_czso_table()`. `dataset_iri`
#' is the unique identifier of the dataset in the national catalogue and also the URL
#' containing all metadata for the dataset.
#' @param search_terms a regex pattern, or a vector of regex patterns, to filter the catalogue by.
#' A case-insensitive filter is performed on the title, description and keywords.
#' The search returns only catalogue entries where all the patterns are matched anywhere within the title, description or keywords.
#' @return a data frame with details on all CZSO datasets available in the Czech National Open Data Catalogue.
#' The columns are fairly well described by their names, except:
#'
#' - some columns contain IRIs instead of human readable text; still you can deduce the content from the IRI.
#' - the `spatial` columns contains an IRI ending in the pattern `{unit_type}`/`{unit_code}`.
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
#' czso_get_catalogue(search_terms = c("kraj", "me?zd"))
#' }
czso_get_catalogue <- function(search_terms = NULL) {
  url <- "https://vdb.czso.cz/pll/eweb/lkod_ld.seznam"

  if(is_above_bigsur()) stop_on_openssl()

  ctlg <- suppressWarnings(readr::read_csv(url,
                                           col_types = readr::cols(
                                             dataset_iri = readr::col_character(),
                                             dataset_id = readr::col_character(),
                                             title = readr::col_character(),
                                             provider = readr::col_character(),
                                             description = readr::col_character(),
                                             spatial = readr::col_character(),
                                             modified = readr::col_date(format = ""),
                                             page = readr::col_character(),
                                             periodicity = readr::col_character(),
                                             start = readr::col_date(format = ""),
                                             end = readr::col_date(format = ""),
                                             keywords_all = readr::col_character()
                                           ))) %>%
    dplyr::mutate(periodicity = dplyr::recode(.data$periodicity, nikdy = "NEVER"))

  if(!is.null(search_terms)) {
    czso_filter_catalogue(ctlg, search_terms)
  } else {
    ctlg
  }

}

#' Filter the catalogue using a set of keywords
#'
#' @param catalogue a catalogue as returned by `czso_get_catalogue()`
#' @param search_terms #' A regex pattern (incl. plain text), or a vector of regex patterns, to filter the catalogue by.
#' A case-insensitive filter is performed on the title, description and keywords.
#' The search returns only catalogue entries where all the patterns are matched anywhere within the title, description or keywords.
#'
#' @return A tibble with the filtered catalogue.
#' @export
#'
#' @family Core workflow
#' @examples
#' ctlg <- czso_get_catalogue()
#' czso_filter_catalogue(ctlg, search_terms = c("kraj", "me?zd"))
#' czso_filter_catalogue(ctlg, search_terms = c("úmrt", "orp"))
#' czso_filter_catalogue(ctlg, search_terms = c("kraj", "vazba", "orp"))
#' czso_filter_catalogue(ctlg, search_terms = c("ISCO", "číselník"))
#' czso_filter_catalogue(ctlg, search_terms = c("zaměstnání", "číselník"))
czso_filter_catalogue <- function(catalogue, search_terms) {
  # Initialize an empty vector to store IDs of the relevant catalogue entries
  relevant_ids <- c()

  # Iterate over each row in the input data frame
  for (i in 1:nrow(catalogue)) {
    row <- catalogue[i, c("dataset_id", "title", "description", "keywords_all")]
    # Check if any of the patterns match in any of the three text columns
    if (all(sapply(search_terms, function(pattern) any(grepl(pattern, row,
                                                             ignore.case = TRUE))))){
      # Append the row to the filtered data frame
      relevant_ids <- c(relevant_ids, row[["dataset_id"]])
    }
  }
  filtered_catalogue <- catalogue[catalogue$dataset_id %in% relevant_ids, ]

  filtered_catalogue
}


