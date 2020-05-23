
<!-- README.md is generated from README.Rmd. Please edit that file -->

# czso <img src='man/figures/logo.png' align="right" height="138" />

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/czso)](https://CRAN.R-project.org/package=czso)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/grand-total/czso)](https://CRAN.R-project.org/package=czso)
[![CRAN monthly
downloads](https://cranlogs.r-pkg.org/badges/last-month/czso)](https://CRAN.R-project.org/package=czso)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![Travis build
status](https://travis-ci.org/petrbouchal/czso.svg?branch=master)](https://travis-ci.org/petrbouchal/czso)
[![R build
status](https://github.com/petrbouchal/czso/workflows/R-CMD-check/badge.svg)](https://github.com/petrbouchal/czso/actions)
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

Additionally, the package provides access to metadata on datasets.

## Installation

You can install the package from CRAN:

``` r
install.packages("czso")
```

You can install the latest in-development release from
[github](https://github.com/petrbouchal/czso) with:

``` r
remotes::install_github("petrbouchal/czso", ref = github_release())
```

or the latest version with:

``` r
remotes::install_github("petrbouchal/czso")
```

I also keep binaries in a `drat` repo, which you can access by

    install.packages("czso", repos = "https://petrbouchal.github.io/drat")

## Example

Say you are looking for a dataset whose title refers to wages
(mzda/mzdy):

First, retrieve the list of available CZSO datasets:

``` r
library(czso)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(stringr))

catalogue <- czso_get_catalogue()
#> ℹ Reading data from data.gov.cz
#> ✓ Done downloading and reading data
#> ℹ Transforming data
```

Now search for your terms of interest in the dataset titles:

``` r
catalogue %>% 
  filter(str_detect(title, "[Mm]zd[ay]")) %>% 
  select(dataset_id, title, description)
#> # A tibble: 2 x 3
#>   dataset_id title                           description                                            
#>   <chr>      <chr>                           <chr>                                                  
#> 1 110080     Průměrná hrubá měsíční mzda a … Datová sada obsahuje časovou řadu průměrných měsíčních…
#> 2 110079     Zaměstnanci a průměrné hrubé m… Datová sada obsahuje časovou řadu počtu zaměstnanců a …
```

You could also search in descriptions or keywords which are also
retrieved into the catalogue.

We can see the `dataset_id` for the required dataset - now use it to get
the dataset:

``` r
czso_get_table("110080")
#> # A tibble: 720 x 14
#>    idhod hodnota stapro_kod SPKVANTIL_cis SPKVANTIL_kod POHLAVI_cis POHLAVI_kod   rok uzemi_cis
#>    <chr>   <dbl> <chr>      <chr>         <chr>         <chr>       <chr>       <int> <chr>    
#>  1 7459…   26211 5958       <NA>          <NA>          <NA>        <NA>         2013 97       
#>  2 7459…   29026 5958       <NA>          <NA>          102         1            2013 97       
#>  3 7459…   22729 5958       <NA>          <NA>          102         2            2013 97       
#>  4 7459…   22266 5958       7636          Q5            <NA>        <NA>         2013 97       
#>  5 7459…   23955 5958       7636          Q5            102         1            2013 97       
#>  6 7459…   20271 5958       7636          Q5            102         2            2013 97       
#>  7 7459…   26033 5958       <NA>          <NA>          <NA>        <NA>         2012 97       
#>  8 7459…   28873 5958       <NA>          <NA>          102         1            2012 97       
#>  9 7459…   22496 5958       <NA>          <NA>          102         2            2012 97       
#> 10 7459…   21997 5958       7636          Q5            <NA>        <NA>         2012 97       
#> # … with 710 more rows, and 5 more variables: uzemi_kod <chr>, STAPRO_TXT <chr>, uzemi_txt <chr>,
#> #   SPKVANTIL_txt <chr>, POHLAVI_txt <chr>
```

You can retrieve the schema for the dataset:

``` r
czso_get_table_schema("110080")
#> # A tibble: 14 x 5
#>    name          titles        `dc:description`                                    required datatype
#>    <chr>         <chr>         <chr>                                               <lgl>    <chr>   
#>  1 idhod         idhod         "unikátní identifikátor údaje Veřejné databáze ČSÚ" TRUE     string  
#>  2 hodnota       hodnota       "zjištěná hodnota"                                  TRUE     number  
#>  3 stapro_kod    stapro_kod    "kód statistické proměnné ze systému SMS UKAZ"      TRUE     string  
#>  4 spkvantil_cis spkvantil_cis "kód číselníku pro kvantil"                         TRUE     string  
#>  5 spkvantil_kod spkvantil_kod "kód položky z číselníku pro kvantil"               TRUE     string  
#>  6 pohlavi_cis   pohlavi_cis   "kód číselníku pro pohlaví"                         TRUE     string  
#>  7 pohlavi_kod   pohlavi_kod   "kód položky číselníku pro pohlaví"                 TRUE     string  
#>  8 rok           rok           "rok referenčního období ve formátu RRRR"           TRUE     number  
#>  9 uzemi_cis     uzemi_cis     "kód číselníku pro referenční území "               TRUE     string  
#> 10 uzemi_kod     uzemi_kod     "kód položky číselníku pro referenční území"        TRUE     string  
#> 11 uzemi_txt     uzemi_txt     "text položky z číselníku pro referenční území"     TRUE     string  
#> 12 stapro_txt    stapro_txt    "text statistické proměnné"                         TRUE     string  
#> 13 spkvantil_txt spkvantil_txt "text položky číselníku pro kvantil"                TRUE     string  
#> 14 pohlavi_txt   pohlavi_txt   "text položky číselníku pro pohlaví"                TRUE     string
```

and download the documentation in PDF:

``` r
czso_get_dataset_doc("110080", action = "download", format = "pdf")
#> ✓ Downloaded https://www.czso.cz/documents/62353418/109720808/110080-19dds.pdf to 110080-19dds.pdf
```

### A note about “tables” and “datasets”

In the parlance of the official open data catalogue, a `dataset` can
have multiple distributions (typically multiple formats of the same
data). These are called resources in the internals, and manifest as
tables in this package. Some metainformation is the property of a
dataset (the documentation), while other - the schema - is the property
of a table. Hence the function names in this package. This is to keep
things organised even if the CZSO almost always provides only one table
per dataset and appends new data to it over time.

## Data sources

The catalogue is drawn from <https://data.gov.cz> through the [SPARQL
endpoint](https://data.gov.cz/sparql).

The data and specific metadata is then accessed via the `package_show`
endpoint of the CZSO API at (example)
<https://vdb.czso.cz/pll/eweb/package_show?id=290038r19>.

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
    accessing the API once per `czso_get_table()` call, relying on a
    different system for `czso_get_catalogue()`. Hence, *do not use this
    package for harvesting large numbers of datasets from the CZSO.*

### Acknowledgments

Thanks to @jakubklimek and @martinnecasky for [helping me figure
out](https://github.com/opendata-mvcr/nkod/issues/19) the [SPARQL
endpoint](https://data.gov.cz/sparql) on the Czech National Open Data
Catalogue.

### The logo

An homage to the CZSO’s work in releasing its data in an open format,
something that is not necessarily in its DNA.

It alludes to the shades of the country reflected in the tabular data
provided, By interspersing the comma symbol into the name of the
package, it refers to both integration between statistics and open data
and the slight disruption that the world of statistics undergoes when
that integration happens.

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

## Contributing / code of conduct

Please note that the ‘czso’ project is released with a [Contributor Code
of Conduct](https://petrbouchal.github.io/czso/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
