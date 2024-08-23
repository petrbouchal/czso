# 100013 = Těžba dřeva podle druhů dřevin a typu nahodilé těžby

test_that("download works", {
  skip_on_cran()
  dta <- czso_get_table("100013")
  expect_true(is.data.frame(dta)) # je data frame?
  expect_gte(nrow(dta), 399) # 399 = počet řádků k 2020-04-23

  cdlst <- czso_get_codelist("cis100")
  expect_true(is.data.frame(cdlst)) # je data frame?
  expect_gte(nrow(cdlst), 14) # 14 = počet sloupců k 2020-04-23
})

test_that("top-level fns work for all data types", {
  skip_on_cran()
  expect_warning(dta_volby_api <- czso_get_table("kz2016vysledky"))
  expect_warning(dta_volby_api_param <- czso_get_table("kz2020CZ0715"))
  expect_warning(dta_volby_xml <- czso_get_table("kv2022cvs"))
  dta_zip <- czso_get_table("340130")
  dta_cis <- czso_get_codelist(65)
  dta_vazba <- czso_get_codelist("cis100vaz65")
  dta_dataset <- czso_get_table("100013")

  expect_gt(nrow(dta_dataset), 494)
  expect_gt(nrow(dta_zip), 141000)
  expect_gte(nrow(dta_cis), 206)
  expect_gte(nrow(dta_vazba), 206)

  expect_gte(ncol(dta_dataset), 16)
  expect_gte(ncol(dta_zip), 15)
  expect_gte(ncol(dta_cis), 9)
  expect_gte(ncol(dta_vazba), 10)

})

