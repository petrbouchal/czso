library(rnaturalearth)
library(rnaturalearthdata)
library(tidyverse)
# pak::pkg_install("dmi3kno/bunny")
library(bunny)
library(magick)
library(emojifont)
library(fontawesome)
library(svglite)

cz <- ne_countries(scale = "medium", returnclass = "sf") %>%
  filter(adm0_a3 == "CZE") %>%
  select()
plot(cz, max.plot = 1)

# https://pkgdown.r-lib.org/reference/build_favicon.html
# https://pkgdown.r-lib.org/reference/build_home.html
# https://www.ddrive.no/post/making-hex-and-twittercard-with-bunny-and-magick/

hex_border <- image_canvas_hexborder(border_color = "#c30011", border_size = 2)
hex_canvas <- image_canvas_hex(border_color = "#c30011", border_size = 5, fill_color = "white")
hex_canvas

icon <- fontawesome::fa("table")
write_lines(icon, "x.svg")
icon <- image_read_svg("x.svg", width = 400) %>%
  image_colorize(100, "white")
icon

ggplot() +
  geom_sf(data = cz, colour = NA, fill = '#0054a8') +
  theme_void()
ggsave("prep/cz_for_hex.png", width = 12, height = 10, units = "cm",
       bg = "transparent")

cz_for_hex <- image_read("prep/cz_for_hex.png")
cz_for_hex
img_hex <- hex_canvas %>%
  bunny::image_compose(cz_for_hex, gravity = "north", offset = "+0+220") %>%
  bunny::image_compose(icon, gravity = "north", offset = "+0+650") %>%
  image_annotate("czso", size = 400, gravity = "south", location = "+0+320",
                 font = "Tahoma", color = "#c30011") %>%
  bunny::image_compose(hex_border, gravity = "center", operator = "Over")
img_hex

img_hex %>%
  image_convert("png") %>%
  image_write("prep/logo.png")
img_hex %>%
  image_scale("300x300")

img_hex %>%
  image_scale("1200x1200") %>%
  image_write(here::here("prep", "logo_hex_large.png"), density = 600)

img_hex %>%
  image_scale("200x200") %>%
  image_write(here::here("logo.png"), density = 600)

img_hex_for_pkgdown <- img_hex %>%
  image_scale("480x556") %>%
  image_write(here::here("prep/logo.png"), density = 600, quality = 100)

img_hex_gh <- img_hex %>%
  image_scale("400x400")

gh_logo <- bunny::github %>%
  image_scale("40x40") %>%
  image_colorize(70, "grey")

gh <- image_canvas_ghcard("black") %>%
  image_compose(img_hex_gh, gravity = "East", offset = "+80+0") %>%
  image_annotate("Czech statistics open data for R", gravity = "West", location = "+80-30",
                 color = "white", size = 40, font = "Fira Sans") %>%
  image_compose(gh_logo, gravity = "West", offset = "+110+45") %>%
  image_annotate("petrbouchal/czso", gravity = "West", location = "+160+45",
                 size = 35, font="Fira Sans", color = "grey") %>%
  image_border_ghcard("grey")

gh

gh %>%
  image_write(here::here("prep", "czso_ghcard.png"))
