
#' Get dataset metadata
#'
#' Get metadata from CZSO API, which can be somewhat more detailed/readable than
#' what is provided in the dataset's entry in the output of `czso_get_dataset()`.
#'
#' As far as I can tell there is no way to get the metadata in English, though
#' some key datasets, such as codelists, do have English-language documentation.
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
  if(!curl::has_internet()) cli::cli_abort(c("No internet connection. Cannot continue. Retry when connected."))
  url <- paste0("https://vdb.czso.cz/pll/eweb/lkod_ld.datova_sada?id=", dataset_id)
  mtdt_c <- httr::GET(url,
                      httr::user_agent(ua_string)) %>%
    httr::stop_for_status() %>%
    httr::content(as = "text")
  # mtdt_c_sanitised <- gsub("\\t", "\\s", mtdt_c)
  mtdt <- jsonlite::fromJSON(mtdt_c)
  # print(mtdt)
  if(is.null(mtdt)) cli::cli_abort("No dataset found with this ID.")
  return(mtdt)
}

czso_get_resources <- function(dataset_id) {
  mtdt <- czso_get_dataset_metadata(dataset_id)
  return(mtdt[["distribuce"]])
}


# Lower-level functions ------------------------------------------------------

czso_read_csv <- function(dfile) {
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

czso_download_file <- function(url, dfile) {
  if(is_above_bigsur()) stop_on_openssl()
  curl_handle <- curl::new_handle() %>%
    curl::handle_setheaders(.list = ua_header)
  curl::curl_download(url, dfile, handle = curl_handle)
  return(dfile)
}

czso_download_if_needed <- function(url, dfile, force_redownload) {
  if(is_above_bigsur()) stop_on_openssl()
  if(file.exists(dfile) & !force_redownload) {
    cli::cli_inform(c(i = "File already in {.path {dirname(dfile)}}, not downloading.",
                     "Set {.code force_redownload = TRUE} if needed."))
    return(dfile)
  } else {
    curl_handle <- curl::new_handle() %>%
      curl::handle_setheaders(.list = ua_header)
    curl::curl_download(url, dfile, handle = curl_handle)
    return(dfile)
  }
}

czso_get_dl_path <- function(dataset_id, dir = tempdir(), ext) {
  td <- file.path(dir, dataset_id)
  dir.create(td, showWarnings = FALSE, recursive = TRUE)
  dfile <- paste0(td, "/ds_", dataset_id, ".", ext)
  return(dfile)
}

slova <- c(url = stringi::stri_unescape_unicode("p\\u0159\\u00edstupov\\u00e9_url"),
           schema = stringi::stri_unescape_unicode("sch\\u00e9ma"),
           format = stringi::stri_unescape_unicode("form\\u00e1t"))

czso_get_resource_pointer <- function(dataset_id, resource_num = 1) {
  rsrc0 <- czso_get_resources(dataset_id)[resource_num,]
  rsrc <- rsrc0[,c(slova['url'], slova['format'], slova['schema'])]
  names(rsrc)[3] <- 'meta_link'
  return(rsrc)
}

czso_get_url <- function(dataset_id = NULL, resource_num = 1) {
  pntr <- czso_get_resource_pointer(dataset_id = dataset_id, resource_num = resource_num)
  return(pntr[[slova['url']]])
}


# Top-level workflow functions ------------------------------------------------------------

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
#' - `idhod`: a unique ID of the value in the CZSO database. This does not allow
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

  if(grepl("^cis", dataset_id)) {

    cd <- paste0('czso_get_codelist(', "\"", dataset_id ,"\")")

    cli::cli_inform(c(i = "The dataset you are fetching seems to be a codelist."))
    cli::cli_inform("Use {.code {cd}} to load it using a dedicated function.")
  }

  ptr <- czso_get_resource_pointer(dataset_id, resource_num = resource_num)
  url <- ptr[[slova['url']]]
  type <- ptr[[slova['format']]]
  ext <- tools::file_ext(url)
  if(ext == "" | is.null(ext)) {
    extm <- regexpr("(?<=\\/)[a-zA-Z0-9]{2,5}$", type, perl = TRUE)
    ext <- tolower(regmatches(type, extm))
  }

  if(is.null(dest_dir)) dest_dir <- getOption("czso.dest_dir",
                                              default = tempdir())

  dfile <- czso_get_dl_path(dataset_id, dest_dir, ext)

  czso_download_if_needed(url, dfile, force_redownload)

  # print(dfile)

  if(type == "http://publications.europa.eu/resource/authority/file-type/CSV") {
    action <- "read"
  } else if(type == "application/zip") {
    utils::unzip(dfile, exdir = dirname(dfile))
    flist <- list.files(dirname(dfile), pattern = "(CSV|csv)$")
    if((length(flist) == 1) & (tools::file_ext(flist[1]) %in% c("CSV", "csv"))) {
      action <- "read"
    } else if (length > 1) {
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
            rtrn <- czso_read_csv(dfile)
            invi <- F
          },
          listone = {
            cli::cli_warn(c(x = "Unable to read this kind of file ({.value {type}}) automatically.",
                                     i = "It is saved in {.path {dfile}}."))
            rtrn <- dfile
            invi <- T
          },
          listmore = {
            cli::cli_alert(c(x = "Multiple files in archive.",
                             i = "They are saved in {.path {dirname(dfile)}}"))
            rtrn <- flist
            invi <- T

          }
  )
  if(invi) invisible(rtrn) else return(rtrn)
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
#' @family Core workflow
czso_get_codelist <- function(codelist_id,
                              language = c("cs", "en"),
                              dest_dir = NULL,
                              resource_num = NULL,
                              force_redownload = FALSE) {

  lng <- match.arg(language)

  stopifnot(length(codelist_id) <= 2)

  if(length(codelist_id) == 1) {
    if(is.numeric(codelist_id) | grepl("^[0-9]{2,4}$", codelist_id)) {
      codelist_id <- paste0("cis", codelist_id)
    }
  } else if(length(codelist_id) == 2) {
    if(is.numeric(codelist_id) | all(grepl("^[0-9]{2,4}$", codelist_id))) {
      codelist_id <- paste0("cis", codelist_id[1], "vaz", codelist_id[2])
    }
  }

  if(!grepl("^cis", codelist_id)) {
    cli::cli_alert_warning(c("The value you passed to {.var codelist_id} does not seem to indicate a codelist.",
                             "This may cause unexpected results."))
  }

  cis_meta <- czso_get_resources(codelist_id)

  cis_url <- cis_meta[cis_meta[slova['format']] == "http://publications.europa.eu/resource/authority/file-type/CSV",
                      slova['url']]

  if(length(cis_url) < 1) {
    # usethis::ui_stop(c("No CSV distribution for this codelist found.",
    #                    "You can download the codelist in the format provided using {ui_code(x = stringr::str_glue('czso_get_table(\"{codelist_id}\")'))} and read it in manually.",
    #                    "Use {ui_code(x = stringr::str_glue('czso_get_dataset_metadata(\"{codelist_id}\")'))} to see which formats are available."))

    if(is.null(resource_num)) resource_num <- 1

    cli::cli_inform("No documented CSV distribution found for this codelist. Using workaround.")

    cis_url <- czso_get_resource_pointer(codelist_id, 1)[["url"]]
    cis_url <- sub("format\\=0$", "format=2&separator=,", cis_url)
  }

  if(lng == "en") cis_url <- sub("cisjaz=203", "cisjaz=8260", cis_url)

  if(is.null(dest_dir)) dest_dir <- getOption("czso.dest_dir",
                                              default = tempdir())
  dfile <- czso_get_dl_path(codelist_id, dest_dir, "csv")

  czso_download_if_needed(cis_url, dfile, force_redownload)

  dt <- czso_read_csv(dfile)

  return(dt)
}


