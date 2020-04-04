# czso (development version)

# czso 0.2.2

## Prep for CRAN

* add cran-comments.md
* fixed dplyr-related CHECK NOTE
* updated LICENSE for CRAN
* update URL in README

## Bug fixes and minor improvements

* all functions accessing CZSO data now return helpful error if the dataset cannot be found
* fixed deprecation warnings to display correct package name
* added helpful error message for no access to the internet
* spelling corrections
* better error output when CZSO server returns error

# czso 0.2.1

## New function names and deprecations

* all user-facing functions are now `czso_*` to avoid conflicts and aid discovery via auto-complete. Original functions are soft-deprecated.

## Improvements

* improvements to documentation
* added code of conduct and contributing guide

# czso 0.2.0

## New features

* new `get_dataset_doc()` function for accessing documentation
* new `get_table_schema()` function for retrieving table schema
* exported `get_dataset_metadata()` function for accessing detailed metadata

# czso 0.1.5

## Improvements

* get_czso_catalogue() is now much faster as it uses the open data catalogue's API instead of downloading a huge CSV list of all datasets. It is less flexible as it does not allow direct filtering.
* handle encoding of some older datasets, which may not be UTF-8

# czso 0.1.4

* relaxed stringi version requirement to make Win build work

# czso 0.1.3

## Deprecated functions

* both exported functions are renamed to `get_czso_catalogue()` and `get_czso_table()` to avoid clashes with other packages; original functions are soft-deprecated and will be removed in future versions.

## Bug fixes

* fix bug in `get_czso_catalogue()` where an empty tibble was returned because the source CSV was read incorrectly (due to `vroom` handling of newlines inside fields)

# czso 0.1.2

* add per-session caching to `get_catalogue()` and `get_table()`, incl. new `force_redownload` parameter

# czso 0.1.1

* fixed error when loading zipped files in `get_table()`

# czso 0.1.0

* first version with functioning core workflow

# czso 0.0.0.9000

* Added a `NEWS.md` file to track changes to the package.
