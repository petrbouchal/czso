library(httr)
library(tidyverse)
library(jsonlite)

ss <- GET("https://data.gov.cz/zdroj/lok%C3%A1ln%C3%AD-katalogy/CSttstckyU/214608232", accept_json()) %>%
  content()
tt <- ss[[1]][[6]]
urls <- map_chr(tt, 2)

nn <- urls %>% map(~GET(.x, accept_json()) %>% content(auto_unbox = T))
names(nn[[1]][[1]])

nn[[1]][[1]]$`http://www.w3.org/ns/dcat#keyword` %>%
  map(`[[`, 'value') %>%
  map_chr(1)
nn[[1]][[1]]$`http://www.w3.org/ns/dcat#distribution` %>%
  map(`[[`, 'value') %>%
  map_chr(1)

nn %>% map(names)
innams <- nn[[1]] %>% map_dfc(names)

titles <- nn %>% map(1) %>%
  map(`[[`, "http://purl.org/dc/terms/title") %>%
  map(1) %>%
  map_chr(`[[`, "value")

dist <- GET(nn[[9]][[1]]$`http://www.w3.org/ns/dcat#distribution`[[1]]$value, accept_json()) %>%
  content()




