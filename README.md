
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

Say you are looking for a dataset whose title refers to wages
(mzda/mzdy):

First, retrieve the list of available CZSO datasets:

``` r
library(czso)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(stringr))

catalogue <- get_czso_catalogue()
#> ℹ Reading data from data.gov.cz
#> ✔ Done downloading and reading data
#> ℹ Transforming data
```

Now search for your terms of interest in the dataset titles:

``` r
catalogue %>% 
  filter(str_detect(title, "[Mm]zd[ay]")) %>% 
  select(dataset_id, title, description)
#> # A tibble: 2 x 3
#>   dataset_id title                       description                            
#>   <chr>      <chr>                       <chr>                                  
#> 1 110080     Průměrná hrubá měsíční mzd… Datová sada obsahuje časovou řadu prům…
#> 2 110079     Zaměstnanci a průměrné hru… Datová sada obsahuje časovou řadu počt…
```

You could also search in descriptions or keywords which are also
retrieved into the catalogue.

We can see the `dataset_id` for the required dataset - now use it to get
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

You can retrieve the schema for the dataset:

``` r
get_czso_table_schema("110080")
#> # A tibble: 14 x 5
#>    name       titles     `dc:description`                      required datatype
#>    <chr>      <chr>      <chr>                                 <lgl>    <chr>   
#>  1 idhod      idhod      "unikátní identifikátor údaje Veřejn… TRUE     string  
#>  2 hodnota    hodnota    "zjištěná hodnota"                    TRUE     number  
#>  3 stapro_kod stapro_kod "kód statistické proměnné ze systému… TRUE     string  
#>  4 spkvantil… spkvantil… "kód číselníku pro kvantil"           TRUE     string  
#>  5 spkvantil… spkvantil… "kód položky z číselníku pro kvantil" TRUE     string  
#>  6 pohlavi_c… pohlavi_c… "kód číselníku pro pohlaví"           TRUE     string  
#>  7 pohlavi_k… pohlavi_k… "kód položky číselníku pro pohlaví"   TRUE     string  
#>  8 rok        rok        "rok referenčního období ve formátu … TRUE     number  
#>  9 uzemi_cis  uzemi_cis  "kód číselníku pro referenční území " TRUE     string  
#> 10 uzemi_kod  uzemi_kod  "kód položky číselníku pro referenčn… TRUE     string  
#> 11 uzemi_txt  uzemi_txt  "text položky z číselníku pro refere… TRUE     string  
#> 12 stapro_txt stapro_txt "text statistické proměnné"           TRUE     string  
#> 13 spkvantil… spkvantil… "text položky číselníku pro kvantil"  TRUE     string  
#> 14 pohlavi_t… pohlavi_t… "text položky číselníku pro pohlaví"  TRUE     string
```

and download the documentation in PDF:

``` r
get_czso_dataset_doc("110080", action = "download", format = "pdf")
#> ✔ Downloaded https://www.czso.cz/documents/62353418/109720808/110080-19dds.pdf to 110080-19dds.pdf
```

### A note about “tables” and “datasets”

In the parlance of the official open data catalogue, a `dataset` can
have multiple distributions (typically multiple formats of the same
data). These are called resources in the internals, and manifest as
tables in this package. Some metainformation is the property of a table
(the documentation), while other - the schema - is the property of a
table. Hence the function names in this package. This is to keep things
organised even if the CZSO almost always provides only one table per
dataset and appends new data to it over time.

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

Thanks to @jakubklimek and @martinnecasky for [helping me figure
out](https://github.com/opendata-mvcr/nkod/issues/19) the [SPARQL
endpoint](https://data.gov.cz/sparql) on the Czech National Open Data
Catalogue.

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

For various transparency disclosures, see [Hlídač
státu](https://hlidacstatu.cz).

For access to some of Prague’s open geospatial data in R, see
[pragr](https://github.com/petrbouchal/pragr).
