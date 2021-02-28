# Resubmission of patch version

Resubmitting because CRAN automated pre-check (Flavor: r-devel-linux-x86_64-debian-gcc) flagged a URL redirect uncaught by other checks. Now fixed.

## Notes on patch version submitted here:

Main change: correction of embedded SPARQL query to reflect changes in the data catalogue made by the data provide.

No changes to R code made in this version save for a bug fix where a namespace was missing from a function call.

## Test environments

* local R installation on MacOS, R 4.0.4
* ubuntu 16.04 (on r-hub), R 4.0.4
* fedora-clang (devel on r-hub)
* windows (release and devel on win-builder, release on Github Actions)
* macOS (devel on Github Actions)

## R CMD check results

0 errors | 0 warnings | 0 notes

The install failed on these devel platforms:

- r-hub Windows devel - reports missing utf8 package.
- GHA MacOS devel - reports missing usethis package
