test_that("catalogue and filter works", {
  skip_on_cran()

  ctlg <- czso_get_catalogue()
  expect_gte(nrow(ctlg), 900)

  fltrd <- czso_filter_catalogue(ctlg, c("obyv", "obce", "pohlav"))
  expect_gte(nrow(fltrd), 6)
  expect_lt(nrow(fltrd), nrow(ctlg))
})
