
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
  urls <- czso_get_resource_pointer(dataset_id, resource_num)
  schema_url <- urls$meta_link
  is_json <- grepl(pattern = "json$", x = schema_url)
  if(is_json) {
    suppressMessages(suppressWarnings(schema_result <- httr::GET(schema_url, httr::user_agent(ua_string)) %>%
                                        httr::content(as = "text")))
    ds <- suppressMessages(suppressWarnings(jsonlite::fromJSON(schema_result)[["tableSchema"]][["columns"]]))
    rslt <- tibble::as_tibble(ds)
  } else {
    cli::cli_abort(c("Cannot parse this type of file type.",
                     i = "You can get it yourself from {.url {schema_url}}."))
    rslt <- schema_url
  }
  return(rslt)
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
  url_orig <- metadata[['distribuce']][[slova['schema']]]
  doc_url <- switch (frmt,
                     html = url_orig,
                     word = sub("\\.html?", ".docx", url_orig),
                     pdf = sub("\\.html?", ".pdf", url_orig)
  )
  act <- match.arg(action)
  if(is.null(destfile)) {dest <- basename(doc_url)} else {dest <- destfile}
  switch(act,
         open = {
           cli::cli_alert_success("Opening {.url{doc_url}} in browser")
           utils::browseURL(doc_url)},
         download = {utils::download.file(doc_url, destfile = dest, headers = ua_header, quiet = TRUE)
           cli::cli_alert_success("Downloaded {.url {doc_url}} to {.path {dest}}")})
  if(act == "download") rslt <- dest else rslt <- doc_url
  if(act == "return") rslt else invisible(rslt)
}
