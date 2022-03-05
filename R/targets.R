get_file_for_targets <- function(url, resource_pointer, dfile) {

  download_file(url, dfile)

  download_inspected <- inspect_download(resource_pointer, dfile)

  if(download_inspected$action == "read") {
    return(download_inspected$dfile)
  } else {
    stop(paste0("No CSV file or more than one file in downloaded archive."))
  }
}


#' A target factory for using CZSO data in {targets} pipelines
#'
#' The resulting targets will allow you to track as targets the data file, the data, and by
#' default also the upstream URL from which the data file was updated. This ensures
#' traceability and reproducibility: it is clear from which URL the data came, it is
#' clear from which file it was read. The data is only redownloaded if
#' (a) it changes on the server (unless `freeze` is `TRUE`, in which case you have
#'  complete reproducibility regardless of what happend on the data provider's server),
#'  or if (b) the downloaded data file is deleted.
#'
#'  As a baseline, all steps of the data pipeline are tracked via a set of targets:
#'  1. the URL from which a CZSO data file was downloaded
#'  2. the file where it is saved on disk
#'  3. the data object created by loading the data file
#'
#'  By default, (2) and (3) update if change is detected in (1).
#'
#'  There are two modes: automation with updates and reproducibility
#'
#' 1) Automatio with updates as needed (the default): if you leave `freeze` at its default of `FALSE`, the file and data targets will rerun when the file changes on the CZSO server.
#' This means you get new data as it updated, but you are only downloading a file from CZSO when CZSO updated the data.
#' 2) Reproducibility: if you set `freeze` to `TRUE`, the upstream URL will be tracked as a target, but will not be checked for updates,
#'  i.e. if the upstream #' file changes, it will not be redownloaded and the on-disk file and data target will not be updated. The `*_url` target only serves to
#' document the URL from which the data was uploaded, as well as the timestamp.
#' (Note that if you delete the file, the file target will rerun, also causing the data to update if
#' the upstream file on the server has changed.)
#'
#' @param name Unquoted name to be used as the base for naming targets produced by the target factory.
#' @param dataset_id Dataset ID as listed in the `dataset_id` column in the output of `czso_get_catalogue()`.
#' @param dest_dir The directory in which to save the file downloaded from the data provider. Because the file is tracked as a target,
#' this cannot be left blank.
#' @param resource_num Resource number, defaults to 1. Usually does not need to be set manually. Set this to >1 if the default returns an unparsable format.
#' @param freeze Whether to track the upstream URL and rerun target when the file is updated on the data provider's server.
#'
#' @return a list of three targets, named `{name}_url`, `{name}_file` and `{name}`.
#' @family Reproducibility
czso_target_table <- function(name, dataset_id, dest_dir, resource_num = 1, freeze = FALSE) {
  if(!requireNamespace("targets", quietly = TRUE)) {
    cli::cli_abort("This function requires the {.pkg targets} package.")
  }

  name_d <- deparse(substitute(name))
  name_url <- paste0(name_d, "_url")
  name_file <- paste0(name_d, "_file")
  name_data <- paste0(name_d)
  sym_file <- as.symbol(name_file)
  sym_url <- as.symbol(name_url)
  sym_data <- as.symbol(name_data)
  sym_dest_dir <- as.symbol(dest_dir)

  resource_pointer <- get_czso_resource_pointer(dataset_id, resource_num = resource_num)
  url <- resource_pointer[["url"]]

  dfile <- get_dl_path(resource_pointer, dest_dir)

  command_file <- substitute(get_file_for_targets(url, resource_pointer, dfile),
                             env = list(url = sym_url, dfile = dfile,
                                        resource_pointer = resource_pointer,
                                        get_file_for_targets = get_file_for_targets))
  command_data <- substitute(read_czso_csv(file),
                             env = list(file = sym_file,
                                        read_czso_csv = read_czso_csv))

  list(
    targets::tar_target_raw(name_url, url, format = "url", deployment = "main",
                   cue = if(freeze) targets::tar_cue("never") else targets::tar_cue("thorough")
                   ),
    targets::tar_target_raw(name_file, command_file, format = "file"),
    targets::tar_target_raw(name_data, command_data)
  )

}

czso_target_codelist <- function(name, codelist_id, language = c("cs", "en"),
                                 dest_dir, resource_num = NULL, freeze = FALSE) {
  if(!requireNamespace("targets", quietly = TRUE)) {
    cli::cli_abort("This function requires the {.pkg targets} package.")
  }

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

  cis_meta_orig <- get_czso_resources(codelist_id)
  cis_meta_orig$dataset_id <- codelist_id

  cis_meta <- cis_meta_orig[cis_meta_orig$format == "text/csv",]
  cis_url <- cis_meta[cis_meta$format == "text/csv", "url"]

  if(length(cis_url) < 1) {
    # usethis::ui_stop(c("No CSV distribution for this codelist found.",
    #                    "You can download the codelist in the format provided using {ui_code(x = stringr::str_glue('czso_get_table(\"{codelist_id}\")'))} and read it in manually.",
    #                    "Use {ui_code(x = stringr::str_glue('czso_get_dataset_metadata(\"{codelist_id}\")'))} to see which formats are available."))

    if(is.null(resource_num)) resource_num <- 1

    cli::cli_inform("No documented CSV distribution found for this codelist. Using workaround.")

    cis_meta <- cis_meta_orig[1,]
    cis_url <- cis_meta[["url"]]
    cis_url <- sub("format\\=0$", "format=2&separator=,", cis_url)
    cis_meta$format <- "text/csv"
    cis_meta$url <- cis_url
  }

  name_d <- deparse(substitute(name))
  name_url <- paste0(name_d, "_url")
  name_file <- paste0(name_d, "_file")
  name_data <- paste0(name_d)
  sym_file <- as.symbol(name_file)
  sym_url <- as.symbol(name_url)
  sym_data <- as.symbol(name_data)
  sym_dest_dir <- as.symbol(dest_dir)

  dfile <- get_dl_path(cis_meta, dest_dir)

  url <- cis_url
  if(lng == "en") cis_url <- sub("cisjaz=203", "cisjaz=8260", cis_url)

  command_file <- substitute(get_file_for_targets(cis_url, cis_meta, dfile),
                             env = list(url = sym_url, dfile = dfile,
                                        cis_meta = cis_meta,
                                        get_file_for_targets = get_file_for_targets))
  command_data <- substitute(read_czso_csv(file),
                             env = list(file = sym_file,
                                        read_czso_csv = read_czso_csv))

  list(
    targets::tar_target_raw(name_url, url, format = "url", deployment = "main",
                            cue = if(freeze) targets::tar_cue("never") else targets::tar_cue("thorough")
    ),
    targets::tar_target_raw(name_file, command_file, format = "file"),
    targets::tar_target_raw(name_data, command_data)
  )

}
