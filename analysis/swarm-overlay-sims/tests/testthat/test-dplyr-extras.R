test_that(
  "should filter a list by predicate", {
    a_list <- list(
      list(a = 1, b = 2, d = 1),
      list(a = 2, b = 1, d = 2),
      list(a = 1, b = 2, d = 3)
    )
    
    expect_equal(a_list |> filter(a == 1 & b == 2), list(
      list(a = 1, b = 2, d = 1),
      list(a = 1, b = 2, d = 3)
    ))
  }
)

test_that( 
  "should factor caller context in predicate evaluation", {
    a_list <- list(
      list(a = 1, b = 2, d = 1),
      list(a = 2, b = 1, d = 2)
    )
    
    x <- 1
    
    expect_equal(a_list |> filter(a == 2 & b == x), list(
      list(a = 2, b = 1, d = 2)
    ))
  }
)

test_that(
  "should pull attribute as vector", {
    a_list <- list(
      list(a = 1, b = 2, d = 1),
      list(a = 2, b = 1, d = 2),
      list(a = 1, b = 2, d = 3),
      list(b = 2, d = 3)
    )
    
    expect_equal(a_list |> pull(a), c(1, 2, 1, NA))
  }
)

test_that(
  "should return vector when c.XXX is defined", {
    a_list <- list(
      list(a = 1, date = as.Date('2003-03-03')),
      list(a = 2, date = as.Date('2003-03-04')),
      list(a = 1, date = as.Date('2003-03-05'))
    )
    
    column <- a_list |> pull(a)
    
    expect_equal(class(column), "Date")
    expect_equal(column, c(
      as.Date('2003-03-03'), as.Date('2003-03-04'), as.Date('2003-03-05')))
  }
)
