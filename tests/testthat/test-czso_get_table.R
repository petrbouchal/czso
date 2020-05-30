context("download works")

# 100013 = Těžba dřeva podle druhů dřevin a typu nahodilé těžby

expect_true(is.data.frame(czso_get_table("100013"))) # je data frame?
expect_gte(nrow(czso_get_table("100013")), 399) # 399 = počet řádků k 2020-04-23

expect_true(is.data.frame(czso_get_codelist("cis100"))) # je data frame?
expect_gte(nrow(czso_get_codelist("cis100")), 14) # 399 = počet řádků k 2020-04-23
