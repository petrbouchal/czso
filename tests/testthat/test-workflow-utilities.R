test_that("schema retrieval works", {
  expect_no_error(schm <- czso_get_table_schema("340130"))
  expect_gte(ncol(schm), 5)
  expect_gte(nrow(schm), 15)
})

test_that("documentation retrieval works", {
  expect_no_error(doc_url <- czso_get_dataset_doc("340130"))
  expect_match(doc_url, "https\\:\\/\\/csu")
})
