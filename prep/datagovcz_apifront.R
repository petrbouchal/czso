list3 <- GET("https://data.gov.cz/api/v1/solr/query?q=*:*&fq=publisherName:%22%C4%8Cesk%C3%BD%20statistick%C3%BD%20%C3%BA%C5%99ad%22&sort=title_sort%20asc&rows=1000") %>%
  content(as = "text") %>%
  fromJSON()
ds3 <- list3[['response']][['docs']]
ds3 %>% View()

