
<!-- README.md is generated from README.Rmd. Please edit that file -->

# czso <img src='man/figures/logo.png' align="right" height="138" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/czso)](https://CRAN.R-project.org/package=czso)
[![Travis build
status](https://travis-ci.org/petrbouchal/czso.svg?branch=master)](https://travis-ci.org/petrbouchal/czso)
<!-- badges: end -->

The goal of czso is to provide direct, programmatic, hassle-free access
from R to open data provided by the Czech Statistical Office (CZSO).

This is done by

1.  **providing direct access from R to the catalogue of open CZSO
    datasets**, eliminating the hassle from data discovery. Normally
    this is done done through [the CZSO’s product
    catalogue](https://www.czso.cz/csu/czso/otevrena-data-v-katalogu-produktu-csu)
    which is unfortunately a bit clunky, or
    [data.gov.cz](https://data.gov.cz), which is not a natural starting
    point for many.

2.  **providing a function to load a specific dataset to R** directly
    from the CZSO’s datastore, eliminating the friction of copying a
    URL, downloading, unzipping etc.

Additionally, the package provides metadata on datasets.

## Installation

You can install the latest release from
[github](https://github.com/petrbouchal/czso) with:

``` r
remotes::install_github("petrbouchal/czso", ref = github_release())
```

or the latest version with:

``` r
remotes::install_github("petrbouchal/czso")
```

## Example

Imagine you are looking for a dataset whose title refers to wages
(mzda/mzdy):

``` r
library(czso)

# first, retrieve the list of available CZSO datasets, filtering for mzda/mzdy
get_czso_catalogue(title_filter = "mzd[ay]")
#> Reading full list of all datasets available on data.gov.cz...
#> Filtering...
#> # A tibble: 2 x 9
#>   czso_id provider title description dataset topic update_frequency
#>   <chr>   <chr>    <chr> <chr>       <chr>   <chr> <chr>           
#> 1 110079  Český s… Zamě… Datová sad… https:… <NA>  čtvrtletní      
#> 2 110080  Český s… Prům… Datová sad… https:… <NA>  roční           
#> # … with 2 more variables: spatial_coverage <chr>, keywords <chr>
```

We can see the `czso_id` for the required dataset - now use it to get
the dataset:

``` r
get_czso_table("110080")
#> # A tibble: 630 x 14
#>    idhod hodnota stapro_kod SPKVANTIL_cis SPKVANTIL_kod POHLAVI_cis POHLAVI_kod
#>    <chr>   <dbl> <chr>      <chr>         <chr>         <chr>       <chr>      
#>  1 7366…   21554 5958       7636          Q5            <NA>        <NA>       
#>  2 7366…   20378 5958       7636          Q5            <NA>        <NA>       
#>  3 7366…   22447 5958       7636          Q5            <NA>        <NA>       
#>  4 7366…   20266 5958       7636          Q5            <NA>        <NA>       
#>  5 7366…   27162 5958       7636          Q5            <NA>        <NA>       
#>  6 7366…   19183 5958       7636          Q5            <NA>        <NA>       
#>  7 7366…   21782 5958       7636          Q5            <NA>        <NA>       
#>  8 7366…   21383 5958       7636          Q5            <NA>        <NA>       
#>  9 7366…   20527 5958       7636          Q5            <NA>        <NA>       
#> 10 7366…   20153 5958       7636          Q5            <NA>        <NA>       
#> # … with 620 more rows, and 7 more variables: rok <int>, uzemi_cis <chr>,
#> #   uzemi_kod <chr>, STAPRO_TXT <chr>, uzemi_txt <chr>, SPKVANTIL_txt <chr>,
#> #   POHLAVI_txt <chr>
```

Alternatively, you could store the whole CZSO catalogue in an object and
filter yourself. This is especially useful if you expect to need
multiple tries.

``` r
library(dplyr, warn.conflicts = F)
library(stringr, warn.conflicts = F)
catalogue <- get_czso_catalogue()
#> File already in /var/folders/c8/pj33jytj233g8vr0tw4b2h7m0000gn/T//RtmpypkVs8/czso, not downloading. Set `force_redownload` to TRUE if needed.
#> Reading full list of all datasets available on data.gov.cz...
#> Filtering...

catalogue %>% 
  filter(str_detect(title, "mzda"))
#> # A tibble: 1 x 9
#>   czso_id provider title description dataset topic update_frequency
#>   <chr>   <chr>    <chr> <chr>       <chr>   <chr> <chr>           
#> 1 110080  Český s… Prům… Datová sad… https:… <NA>  roční           
#> # … with 2 more variables: spatial_coverage <chr>, keywords <chr>
```

The latter allows you to search through the list - or simply look
through it - without the overhead of reusing the `get_dataset()`
function which downloads and transforms the underlying data.

## Credit and notes

  - not created or endorsed by the Czech Statistical Office, though
    they, as well as [the open data team at the Ministry of
    Interior](https://data.gov.cz/) deserve credit for getting the data
    out there.
  - the package relies on the data.gov.cz catalogue of open data and on
    the CZSO’s local catalogue
  - NB: The robots.txt at the domain hosting the CZSO’s catalogue
    prohibits robots from accessing it; while this may be an
    inappropriate/erroneous setting for what is in essence a data API,
    this package tries to honor the spirit of that setting by only
    accessing the API once per `get_table()` call, relying on a
    different system for `get_catalogue()`. Hence, *do not use this
    package for harvesting large numbers of datasets from the CZSO.*

## See also

This package takes inspiration from the packages

  - [eurostat](https://github.com/rOpenGov/eurostat/)
  - [OECD](https://github.com/expersso/OECD)

which are very useful in their own right - much recommended.

For Czech geospatial data, see
[CzechData](https://github.com/JanCaha/CzechData/) by
[JanCaha](https://github.com/JanCaha/).

For Czech fiscal data, see
[statnipokladna](https://github.com/petrbouchal/statnipokladna).

For access to some of Prague’s open geospatial data in R, see
[pragr](https://github.com/petrbouchal/pragr).