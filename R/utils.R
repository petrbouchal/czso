ua_header <- c("User-Agent" = "github.com/petrbouchal/czso")
ua_string <- "github.com/petrbouchal/czso"

is_above_bigsur <- function() {

  sy <- Sys.info()
  si <- sessionInfo()

  if(is.null(si)) return(FALSE)

  if(sy[["sysname"]] == "Darwin") {
    is_above_12 <- stringr::str_detect(si$running, "\\b1[2-9]\\.")

    if (is_above_12) {
      rslt <- TRUE
    }  else {
      rslt <- FALSE
    }
  } else {
    rslt <- FALSE
  }

  return(rslt)

}

drop_https <- function(url) {
  stringr::str_replace(url, "^https", "http")
}

get_os <- function(){
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin')
      os <- "osx"
  } else { ## mystery machine
    os <- .Platform$OS.type
    if (grepl("^darwin", R.version$os))
      os <- "osx"
    if (grepl("linux-gnu", R.version$os))
      os <- "linux"
  }
  tolower(os)
}
