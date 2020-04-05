# Resubmission

## Corrections made

* added link to data provider in Description field of DESCRIPTION
* expanded documentation for all functions, with better explanations of what the functions return

## Other changes

* `czso_get_table_schema()` now throws error for non-JSON schema and includes URL in error message
* minor error fixed in `czso_get_table()` to ensure unread files are written with the right extension

## Test environments

* local R installation on MacOS, R 3.6.3
* ubuntu 16.04 (on travis-ci and r-hub), R 3.6.3
* fedora-clang (devel on r-hub)
* win-builder on r-hub (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

CRAN-type checks also produce a note on misspelled word "CZSO".
That is the abbreviation of the statistical agency whose data the package mediates.

## Identifying underlying data sources that the package provides access to

Re URLs: besides the (very general) home page of the agency, there is no single user-friendly 
URL to point to on in the Description field to identify the data source by URL.
More detailed references to web resources are provided in README.md.
