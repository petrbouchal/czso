# New minor version

This version includes several minor improvement and bug fixes and two new features, one of which is an option to store data dumps downloaded from the external source in a custom directory so as to avoid redownloading them later. By default, `tempdir()` is used and the user has to actively set a parameter or option for the package to store any data outside working or temporary directories.

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
