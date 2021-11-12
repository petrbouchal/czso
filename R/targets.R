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
#' FUNCTION_DESCRIPTION
#'
#' @param name DESCRIPTION.
#' @param dataset_id DESCRIPTION.
#' @param dest_dir DESCRIPTION.
#' @param resource_num DESCRIPTION.
#' @param freeze Whether to track the
#'
#' @return a list of three targets, named `{name}_url`, `{name}_file` and `{name}_data`.
#' @examples
#' # ADD_EXAMPLES_HERE
czso_target_table <- function(name, dataset_id, dest_dir, resource_num = 1, freeze = FALSE) {
  if(!requireNamespace("targets", quietly = TRUE)) {
    usethis::ui_stop("This function requires the targets package.")
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
