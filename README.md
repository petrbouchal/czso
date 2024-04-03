
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
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![Mentioned in Awesome Official
Statistics](https://awesome.re/mentioned-badge.svg)](https://github.com/SNStatComp/awesome-official-statistics-software)
[![R-CMD-check](https://github.com/petrbouchal/czso/workflows/R-CMD-check/badge.svg)](https://github.com/petrbouchal/czso/actions)
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

Additionally, the package provides access to metadata on datasets and to
codelists (číselníky) as a special case of datasets listed in the
catalogue.

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

    install.packages("czso", repos = "https://petrbouchal.xyz/drat")

## Example

Say you are looking for a dataset whose title refers to wages
(mzda/mzdy):

First, retrieve the list of available CZSO datasets:

``` r
library(czso)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(stringr))

catalogue <- czso_get_catalogue()
```

Now search for your terms of interest in the dataset titles:

``` r
catalogue %>% 
  filter(str_detect(title, "[Mm]zd[ay]")) %>% 
  select(dataset_id, title, description)
#> # A tibble: 2 × 3
#>   dataset_id title                                                   description
#>   <chr>      <chr>                                                   <chr>      
#> 1 110080     Průměrná hrubá měsíční mzda a medián mezd v krajích     Datová sad…
#> 2 110079     Zaměstnanci a průměrné hrubé měsíční mzdy podle odvětví Datová sad…
```

You could also search in descriptions or keywords which are also
retrieved into the catalogue.

We can see the `dataset_id` for the required dataset - now use it to get
the dataset:

``` r
czso_get_table("110080")
#> # A tibble: 1,080 × 14
#>    idhod  hodnota stapro_kod SPKVANTIL_cis SPKVANTIL_kod POHLAVI_cis POHLAVI_kod
#>    <chr>    <dbl> <chr>      <chr>         <chr>         <chr>       <chr>      
#>  1 73662…   21782 5958       7636          Q5            <NA>        <NA>       
#>  2 73662…   25625 5958       <NA>          <NA>          <NA>        <NA>       
#>  3 73662…   28431 5958       <NA>          <NA>          102         1          
#>  4 73662…   22133 5958       <NA>          <NA>          102         2          
#>  5 73662…   23533 5958       7636          Q5            102         1          
#>  6 73662…   19731 5958       7636          Q5            102         2          
#>  7 74595…   26033 5958       <NA>          <NA>          <NA>        <NA>       
#>  8 74595…   28873 5958       <NA>          <NA>          102         1          
#>  9 74595…   22496 5958       <NA>          <NA>          102         2          
#> 10 74595…   21997 5958       7636          Q5            <NA>        <NA>       
#> # ℹ 1,070 more rows
#> # ℹ 7 more variables: rok <int>, uzemi_cis <chr>, uzemi_kod <chr>,
#> #   STAPRO_TXT <chr>, uzemi_txt <chr>, SPKVANTIL_txt <chr>, POHLAVI_txt <chr>
```

You can retrieve the schema for the dataset:

``` r
czso_get_table_schema("110080")
#> # A tibble: 14 × 5
#>    name          titles        `dc:description`                required datatype
#>    <chr>         <chr>         <chr>                           <lgl>    <chr>   
#>  1 idhod         idhod         "unikátní identifikátor údaje … TRUE     string  
#>  2 hodnota       hodnota       "zjištěná hodnota"              TRUE     number  
#>  3 stapro_kod    stapro_kod    "kód statistické proměnné ze s… TRUE     string  
#>  4 spkvantil_cis spkvantil_cis "kód číselníku pro kvantil"     TRUE     string  
#>  5 spkvantil_kod spkvantil_kod "kód položky z číselníku pro k… TRUE     string  
#>  6 pohlavi_cis   pohlavi_cis   "kód číselníku pro pohlaví"     TRUE     string  
#>  7 pohlavi_kod   pohlavi_kod   "kód položky číselníku pro poh… TRUE     string  
#>  8 rok           rok           "rok referenčního období ve fo… TRUE     number  
#>  9 uzemi_cis     uzemi_cis     "kód číselníku pro referenční … TRUE     string  
#> 10 uzemi_kod     uzemi_kod     "kód položky číselníku pro ref… TRUE     string  
#> 11 uzemi_txt     uzemi_txt     "text položky z číselníku pro … TRUE     string  
#> 12 stapro_txt    stapro_txt    "text statistické proměnné"     TRUE     string  
#> 13 spkvantil_txt spkvantil_txt "text položky číselníku pro kv… TRUE     string  
#> 14 pohlavi_txt   pohlavi_txt   "text položky číselníku pro po… TRUE     string
```

and download the documentation in PDF:

``` r
czso_get_dataset_doc("110080", action = "download", format = "pdf")
#> ✔ Downloaded <https://www.czso.cz/documents/62353418/171419376/110080-22dds.pdf> to '110080-22dds.pdf'
```

If you are interested in linking this data to different data, you might
need the NUTS codes for regions. Seeing that the lines with regional
breakdown list `uzemi_cis` as `"100"`, you can get that codelist
(číselník):

``` r
czso_get_codelist(100)
#> # A tibble: 15 × 11
#>    kodjaz akrcis  kodcis chodnota zkrtext text  admplod admnepo cznuts kod_ruian
#>    <chr>  <chr>   <chr>  <chr>    <chr>   <chr> <chr>   <chr>   <chr>  <chr>    
#>  1 CS     KRAJ_N… 100    3000     Extra-… Extr… 2004-0… 9999-0… CZZZZ  <NA>     
#>  2 CS     KRAJ_N… 100    3018     Hl. m.… Hlav… 2001-0… 9999-0… CZ010  19       
#>  3 CS     KRAJ_N… 100    3026     Středo… Stře… 2001-0… 9999-0… CZ020  27       
#>  4 CS     KRAJ_N… 100    3034     Jihoče… Jiho… 2001-0… 9999-0… CZ031  35       
#>  5 CS     KRAJ_N… 100    3042     Plzeňs… Plze… 2001-0… 9999-0… CZ032  43       
#>  6 CS     KRAJ_N… 100    3051     Karlov… Karl… 2001-0… 9999-0… CZ041  51       
#>  7 CS     KRAJ_N… 100    3069     Ústeck… Úste… 2001-0… 9999-0… CZ042  60       
#>  8 CS     KRAJ_N… 100    3077     Libere… Libe… 2001-0… 9999-0… CZ051  78       
#>  9 CS     KRAJ_N… 100    3085     Králov… Král… 2001-0… 9999-0… CZ052  86       
#> 10 CS     KRAJ_N… 100    3093     Pardub… Pard… 2001-0… 9999-0… CZ053  94       
#> 11 CS     KRAJ_N… 100    3107     Kraj V… Kraj… 2001-0… 9999-0… CZ063  108      
#> 12 CS     KRAJ_N… 100    3115     Jihomo… Jiho… 2001-0… 9999-0… CZ064  116      
#> 13 CS     KRAJ_N… 100    3123     Olomou… Olom… 2001-0… 9999-0… CZ071  124      
#> 14 CS     KRAJ_N… 100    3131     Zlínsk… Zlín… 2001-0… 9999-0… CZ072  141      
#> 15 CS     KRAJ_N… 100    3140     Moravs… Mora… 2001-0… 9999-0… CZ080  132      
#> # ℹ 1 more variable: zkrkraj <chr>
```

You would then need to do a bit of manual work to join this codelist
onto the data.

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

- not created or endorsed by the Czech Statistical Office, though they,
  as well as [the open data team at the Ministry of
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
out](https://github.com/datagov-cz/nkod/issues/19) the [SPARQL
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
státu](https://www.hlidacstatu.cz/) and the
[{hlidacr}](https://cran.r-project.org/package=hlidacr) package.

For access to some of Prague’s open geospatial data in R, see
[pragr](https://github.com/petrbouchal/pragr).

## Contributing / code of conduct

Please note that the ‘czso’ project is released with a [Contributor Code
of Conduct](https://petrbouchal.xyz/czso/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
