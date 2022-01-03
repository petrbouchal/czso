httr::GET("http://www.czso.cz/documents/10180/62327313/170242-17data.csv")
tf <- tempfile()
curl::curl_download("http://www.czso.cz/documents/10180/62327313/170242-17data.csv", tf)
readLines(tf, n = 2)
tf <- tempfile()
download.file("http://www.czso.cz/documents/10180/62327313/170242-17data.csv", tf)
readLines(tf, n = 2)

httr::GET("http://vdb.czso.cz/pll/eweb/package_show?id=170242")
tf <- tempfile()
curl::curl_download("http://vdb.czso.cz/pll/eweb/package_show?id=170242", tf)
readLines(tf, n = 2)
tf <- tempfile()
download.file("http://vdb.czso.cz/pll/eweb/package_show?id=170242", tf)
readLines(tf, n = 2)

httr::GET("http://vdb.czso.cz/pll/eweb/lkod_ld.seznam")
tf <- tempfile()
curl::curl_download("http://vdb.czso.cz/pll/eweb/lkod_ld.seznam", tf)
readLines(tf, n = 2)
tf <- tempfile()
download.file("http://vdb.czso.cz/pll/eweb/lkod_ld.seznam", tf)
readLines(tf, n = 2)

readr::read_csv("http://vdb.czso.cz/pll/eweb/lkod_ld.seznam")

httr::GET("http://httpbin.org/get")

# LINKS WITH SAME ISSUE IN OTHER CONTEXTS
# http://debugah.com/solved-python-ssl-handshake-failure-after-upgrading-macos-to-monterey-21497/http://github.com/pmmp/php-build-scripts/issues/130
# http://github.com/Homebrew/brew/issues/12341
# http://developer.apple.com/forums/thread/693828
# https://community.rstudio.com/t/jsonlite-error-in-open-connection/125227/2


tf <- tempfile()
curl::curl_download("http://httpbin.org/get", tf)
readLines(tf, n = 2)
tf <- tempfile()
download.file("http://httpbin.org/get", tf)
readLines(tf, n = 2)

tf <- tempfile()
download.file("http://www.czso.cz/documents/10180/62327313/170242-17data.csv", tf)
readLines(tf, n = 2)
