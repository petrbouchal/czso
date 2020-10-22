# Resubmission #2

Corrected link in README.md to avoid redirect which resulted in a NOTE.

## Test environments

* local R installation on MacOS, R 4.0.2
* ubuntu 16.04 (on travis-ci, r-hub and Github Actions), R 4.0.2
* fedora-clang (devel on r-hub)
* windows (devel on win-builder and r-hub, release on Github Actions)
* macOS (release, devel and on Github Actions)

## R CMD check results

0 errors | 0 warnings | 0 notes

On some remote systems, running examples triggered errors because the data provider seems to be blocking some CI/CD platforms intermittently.

CRAN-type checks also produce a note on misspelled word "CZSO".
That is the abbreviation of the statistical agency whose data the package mediates.
