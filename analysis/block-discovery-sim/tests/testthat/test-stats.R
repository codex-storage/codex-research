test_that(
  "should collect stats as they are input", {
    stats <- Stats$new()
    
    stats$add_stat(a = 1, b = 2, name = 'hello')
    stats$add_stat(a = 1, b = 3, name = 'world')
    
    expect_equal(
      stats$as_tibble(),
      tribble(
        ~a, ~b, ~name,
        1,  2,  'hello',
        1,  3,  'world',
      )
    )
  }
)
