
#' Get catalogue of open CZSO datasets
#'
#' Downloads and processes a list of all registered Czech open data datasets,
#' returning (by default) those accessible through get_table() from the CZSO.
#'
#' If `provider` is NULL, returns the whole list, without CZSO-specific identifier
#' usable in `get_table()`.
#'
#' If `provider` is left unset, returns data frame listing CZSO's datasets, with a
#' `czso_id` column usable in `get_table`.
#'
#' Other values of `provider` must be exact matches. Use `provider_filter` for text/regex matching.
#'
#' All `*_filter` arguments are case sensitive and can be regular expressions.
#'
#' @param provider character, can be of length > 1. Provider to select for. Defaults to (the Czech name of) CZSO. Must be exact match. If set to NULL, returns full list of all datasets.
#' @param title_filter character, text to use for filtering the set by title. Case sensitive. Can be a regular expression.
#' @param description_filter character, text to use for filtering the set by description. Case sensitive.  Can be a regular expression.
#' @param keyword_filter character, text to use for filtering the set by keyword. Case sensitive.  Can be a regular expression.
#' @param provider_filter character, text to use for filtering the set by provider Case sensitive.  Can be a regular expression.
#' @param force_redownload integer. Whether to redownload data source file even if already cached. Defaults to FALSE.
#' @return a data frame. If `provider` param is left to default, contains a column called czso_id, which can be used as dataset_id parameter in get_table().
#' @export
#' @family Core workflow
#' @examples
#' \dontrun{
#' get_czso_catalogue()
#' get_czso_catalogue(NULL)
#' get_czso_catalogue(title_filter = "[Mm]zd[ay]")
#' get_czso_catalogue(provider = "Ministerstvo vnitra")
#' get_czso_catalogue(provider_filter = "[Mm]inisterstvo")
#' }
get_czso_catalogue <- function(provider = "\\u010cesk\\u00fd statistick\\u00fd \\u00fa\\u0159ad",
                          title_filter = NULL,
                          description_filter = NULL,
                          keyword_filter = NULL,
                          provider_filter = NULL,
                          force_redownload = F)
  {
  if(!is.null(provider))
    provider_uni <- stringi::stri_unescape_unicode(provider)
  else provider_uni <- NULL
  td <- paste(tempdir(), "czso", sep = "/")
  dir.create(td, showWarnings = F, recursive = T)
  tf <- paste0(td, "/", "dataset_list.csv")
  if(file.exists(tf) & !force_redownload) {
    message(stringr::str_glue("File already in {td}, not downloading. Set `force_redownload` to TRUE if needed."))
  } else {
    utils::download.file("https://data.gov.cz/soubor/datov%C3%A9-sady.csv", tf, headers = ua_header)
  }
  message("Reading full list of all datasets available on data.gov.cz...")
  dslist0 <- suppressWarnings(suppressMessages(vroom::vroom(tf, num_threads = 1,
                          col_types = readr::cols(.default = "c")))) %>%
    dplyr::rename_all(~stringi::stri_trans_general(., "latin-ascii")) %>%
    dplyr::select(provider = poskytovatel,
                  title = nazev, description = popis, dataset = datova_sada,
                  keywords0 = klicova_slova, topic = tema,
                  update_frequency = periodicita_aktualizace,
                  spatial_coverage = prostorove_pokryti)
  if(is.null(provider)) {
    dslist <- dslist0 %>%
      dplyr::group_by(dataset) %>%
      dplyr::mutate(keywords = stringr::str_c(keywords0, collapse = "; ")) %>%
      dplyr::ungroup() %>%
      dplyr::select(-keywords0) %>%
      dplyr::distinct()
  } else {
    message("Filtering...")
    dslist <- dslist0 %>%
      dplyr::filter(.$provider %in% provider_uni) %>%
      dplyr::group_by(dataset) %>%
      dplyr::mutate(keywords = stringr::str_c(keywords0, collapse = "; ")) %>%
      dplyr::ungroup() %>%
      dplyr::select(-keywords0) %>%
      dplyr::distinct()
    if(provider == "\\u010cesk\\u00fd statistick\\u00fd \\u00fa\\u0159ad") {
      dslist <- dslist %>%
        dplyr::mutate(czso_id = stringr::str_extract(dataset, "(?<=package_show-id-).*$")) %>%
        dplyr::select(czso_id, -provider, dplyr::everything())
    }
  }

  if(!is.null(title_filter)) {
    dslist <- dplyr::filter(dslist, stringr::str_detect(title, title_filter))
  }
  if(!is.null(description_filter)) {
    dslist <- dplyr::filter(dslist, stringr::str_detect(description, description_filter))
  }
  if(!is.null(keyword_filter)) {
    dslist <- dplyr::filter(dslist, stringr::str_detect(keyword_filter, description_filter))
  }
  if(!is.null(provider_filter)) {
    dslist <- dplyr::filter(dslist, stringr::str_detect(provider, description_filter))
  }

  return(dslist)
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
get_catalogue <- function(provider = "\\u010cesk\\u00fd statistick\\u00fd \\u00fa\\u0159ad",
                          title_filter = NULL,
                          description_filter = NULL,
                          keyword_filter = NULL,
                          provider_filter = NULL,
                          force_redownload = F) {
  .Deprecated("get_czso_catalogue")
  get_czso_catalogue(provider = provider,
                 title_filter = title_filter,
                 description_filter = description_filter,
                 keyword_filter = keyword_filter,
                 provider_filter = provider_filter,
                 force_redownload = force_redownload)
}

get_czso_dataset_metadata <- function(dataset_id) {
  url <- paste0("https://vdb.czso.cz/pll/eweb/package_show?id=", dataset_id)
  mtdt <- jsonlite::fromJSON(url)
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
            dt <- suppressWarnings(suppressMessages(readr::read_csv(dfile, col_types = readr::cols(.default = "c",
                                                                 rok = "i",
                                                                 ctvrtleti = "i",
                                                                 hodnota = "d"))))
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

get_czso_table_schema <- function(dataset_id, resource_num = 1) {
  ptr <- get_czso_resource_pointer(dataset_id)[, resource_num]
  url <- ptr$url
  type <- ptr$type

}

get_czso_table_doc <- function(dataset_id, resource_num = 1) {

}
