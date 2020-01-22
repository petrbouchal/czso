
<!-- README.md is generated from README.Rmd. Please edit that file -->

# czso

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/czso)](https://CRAN.R-project.org/package=czso)
<!-- badges: end -->

The goal of czso is to provide direct, programmatic hassle-free access
to open data provided by the Czech Statistical Office (CZSO).

This is done by

1.  **providing direct access from R to the catalogue of open CZSO
    datasets**, eliminating the hassle from data discovery. Normally
    this is done done through [the CZSO’s product
    catalogue](https://www.czso.cz/csu/czso/otevrena-data-v-katalogu-produktu-csu)
    which is unfortunately a bit clunky, or
    [data.gov.cz](https://data.gov.cz), which is not a natural starting
    point for many.

2.  **providing a function to load a specific dataset to R** directly
    from the CZSO’s datastore, eliminating the need to copy a URL, unzip
    etc.

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

This is a basic example which shows you how to solve a common problem:

``` r
library(czso)

get_catalogue(title_regex = "mzd[ay]")
#> Observations: 299,512
#> Variables: 11
#> chr [11]: datová_sada, název, popis, poskytovatel_IRI, poskytovatel, klíčová_slova, prosto...
#> 
#> Call `spec()` for a copy-pastable column specification
#> Specify the column types with `col_types` to quiet this message
#> # A tibble: 2 x 8
#>   czso_id title description dataset keywords topic update_frequency
#>   <chr>   <chr> <chr>       <chr>   <chr>    <chr> <chr>           
#> 1 110080  Prům… Datová sad… https:… Mzda     <NA>  roční           
#> 2 110079  Zamě… Datová sad… https:… zaměstn… <NA>  čtvrtletní      
#> # … with 1 more variable: spatial_coverage <chr>
get_table("110080")
#> [1] "/var/folders/c8/pj33jytj233g8vr0tw4b2h7m0000gn/T//Rtmpudrr94/czso/110080/ds_110080.csv"
#> Registered S3 methods overwritten by 'readr':
#>   method           from 
#>   format.col_spec  vroom
#>   print.col_spec   vroom
#>   print.collector  vroom
#>   print.date_names vroom
#>   print.locale     vroom
#>   str.col_spec     vroom
#> Warning: The following named parsers don't match the column names: ctvrtleti
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

## See also

This package takes inspiration from

  - eurostat
  - OECD

which are very useful in their own right - much recommended.
