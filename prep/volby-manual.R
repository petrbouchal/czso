library(czso)

czso:::download_if_needed("https://volby.cz/opendata/ps2021/csv_od/pst4p_csv_od.zip",
                     "volby.zip", force_redownload = FALSE)

czso_get_table("ps2021pst4p")
czso_get_table("ps2021pst4")
