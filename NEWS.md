# czso (development version)

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
