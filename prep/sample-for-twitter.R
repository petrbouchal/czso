library(czso)
library(tidyverse)
library(lubridate)

czso_get_catalogue() %>%
  filter(str_detect(title, "[Kk]onjunk"))

konj <- czso_get_table("070013")

konj %>%
  filter(is.na(bazobdobiod), obdobido > "2015-01-31", is.na(cznace_txt)) %>%
  mutate(obdobi_rok = year(obdobido),
         obdobi_mesic = as.integer(month(obdobido))) %>%
  ggplot(aes(obdobi_mesic, hodnota, colour = obdobi_rok, group = obdobi_rok)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ stapro_txt) +
  # ptrr::scale_x_number_cz() +
  scale_color_viridis_c(direction = -1, guide = guide_legend(title = NULL)) +
  scale_x_continuous(n.breaks = 12) +
  ptrr::theme_ptrr("y", multiplot = T) +
  labs(title = "Indikátory důvěry",
       subtitle = "Konjunkturální průzkum, data ČSÚ",
       caption = "Zdroj: ČSÚ, dataset '070013'. Sběr dat GfK pro ČSÚ")

konj %>%
  filter(is.na(bazobdobiod), obdobido > "2015-01-31", is.na(cznace_txt)) %>%
  ggplot(aes(obdobido, hodnota, colour = stapro_txt)) +
  geom_line() +
  geom_point() +
  labs(title = "Indikátory důvěry",
       subtitle = "Konjunkturální průzkum, data ČSÚ",
       caption = "Zdroj: ČSÚ, dataset '070013'. Sběr dat GfK pro ČSÚ")
