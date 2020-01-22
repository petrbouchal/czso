
#' Get catalogue of open CZSO datasets
#'
#' FUNCTION_DESCRIPTION
#'
#' @param provider DESCRIPTION.
#' @param title_regex DESCRIPTION.
#' @param description_regex DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#' @export
#' @examples
#' # ADD_EXAMPLES_HERE
get_catalogue <- function(provider = "\\u010cesk\\u00fd statistick\\u00fd \\u00fa\\u0159ad", title_regex = NULL,
                          description_regex = NULL) {
  dslist <- vroom::vroom("https://data.gov.cz/soubor/datov%C3%A9-sady.csv") %>%
    dplyr::filter(poskytovatel %in% provider) %>%
    dplyr::rename_all(~stringi::stri_trans_general(., "latin-ascii")) %>%
    dplyr::distinct(datova_sada, .keep_all = T) %>%
    dplyr::select(title = nazev, description = popis, dataset = datova_sada,
                  keywords = klicova_slova, topic = tema, update_frequency = periodicita_aktualizace, spatial_coverage = prostorove_pokryti) %>%
    dplyr::mutate(czso_id = stringr::str_extract(dataset, "(?<=package_show-id-).*$")) %>%
    dplyr::select(czso_id, dplyr::everything())

  if(!is.null(title_regex)) {
    dslist <- dplyr::filter(dslist, stringr::str_detect(title, title_regex))
  }
  if(!is.null(description_regex)) {
    dslist <- dplyr::filter(dslist, stringr::str_detect(description, description_regex))
  }

  return(dslist)
}

get_dataset_metadata <- function(dataset_id) {
  url <- paste0("https://vdb.czso.cz/pll/eweb/package_show?id=", dataset_id)
  mtdt <- jsonlite::fromJSON(url)
  return(mtdt)
}

get_resources <- function(dataset_id) {
  mtdt <- get_dataset_metadata(dataset_id)
  return(mtdt$result$resources)
}

get_resource_pointer <- function(dataset_id, resource_num = 1) {
  rsrc <- get_resources(dataset_id)[resource_num,] %>%
    dplyr::select(url, format, meta_link = describedBy, meta_format = describedByType)
  return(rsrc)
}

#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param dataset_id DESCRIPTION.
#' @param resource_num DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#' @export
#' @examples
#' # ADD_EXAMPLES_HERE
get_table <- function(dataset_id, resource_num = 1) {
  ptr <- get_resource_pointer(dataset_id)
  url <- ptr$url
  type <- ptr$format
  ext <- tools::file_ext(url)
  td <- paste0(tempdir(), "/czso/", dataset_id, "/")
  dir.create(td, recursive = T, showWarnings = F)

  dfile <- paste0(td, "ds_", dataset_id, ".", ext)
  utils::download.file(url, destfile = dfile, headers = ua_header)

  print(dfile)

  if(type == "text/csv") {
    action <- "read"
  } else if(type == "application/zip") {
    utils::unzip(dfile)
    flist <- list.files(td)
    if(length(flist) == 1 & tools::file_ext(flist[1] == "csv")) {
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
      dt <- readr::read_csv(dfile, col_types = readr::cols(.default = "c",
                                                           rok = "i",
                                                           ctvrtleti = "i",
                                                           hodnota = "d"))
      rtrn <- dt
      },
    listone = {
      message(paste0("Unable to read this kind of file automatically. It is saved in ", dfile, "."))
      rtrn <- dfile
    },
    listmore = {
      message(paste0("Multiple files in archive. They are saved in ", td))
      print(flist)
      rtrn <- flist

    }
  )
  return(rtrn)
}

get_table_schema <- function(dataset_id, resource_num = 1) {
  ptr <- get_resource_pointer(dataset_id)[, resource_num]
  url <- ptr$url
  type <- ptr$type

}

get_table_doc <- function(dataset_id, resource_num = 1) {

}
