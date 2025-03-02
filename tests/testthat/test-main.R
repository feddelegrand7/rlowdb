library(testthat)
library(jsonlite)

test_db_file <- tempfile(fileext = ".json")
db <- rlowdb$new(test_db_file)

test_that("Database initializes correctly", {
  expect_equal(db$get_data(), list())
})

test_that("Inserting records works correctly", {
  db$insert("posts", list(id = 1, title = "LowDB in R", views = 100))
  db$insert("posts", list(id = 2, title = "Data Management", views = 250))

  data <- db$get_data()
  expect_true("posts" %in% names(data))
  expect_equal(length(data$posts), 2)
  expect_equal(data$posts[[1]]$id, 1)
})

test_that("Finding records works correctly", {
  result <- db$find("posts", "id", 1)
  expect_equal(length(result), 1)
  expect_equal(result[[1]]$title, "LowDB in R")
})

test_that("Updating records works correctly", {
  db$update("posts", "id", 1, list(views = 150))
  updated_post <- db$find("posts", "id", 1)
  expect_equal(updated_post[[1]]$views, 150)

  expect_error(db$update("posts", "id", 99, list(views = 200)), "Error: No record found")
})

test_that("Deleting records works correctly", {
  db$delete("posts", "id", 2)
  data <- db$get_data()

  expect_equal(length(data$posts), 1)
  expect_equal(data$posts[[1]]$id, 1)

  expect_error(db$delete("posts", "id", 99), "Error: No record found")
})

test_that("Querying records works correctly with single condition", {
  db$insert("posts", list(id = 3, title = "Advanced R", views = 300))

  # Query posts with views > 100
  high_views <- db$query("posts", "views > 200")
  expect_equal(length(high_views), 1)
  expect_equal(high_views[[1]]$id, 3)

  # Query posts with id == 1
  result <- db$query("posts", "id == 1")
  expect_length(result, 1)
  expect_equal(result[[1]]$title, "LowDB in R")
})

test_that("Querying records works correctly with multiple conditions", {
  result <- db$query("posts", "views > 200 & id > 2")
  expect_length(result, 1)
  expect_equal(result[[1]]$title, "Advanced R")

  result <- db$query("posts", "views > 200 | id == 1")
  expect_length(result, 2)
})

test_that("Query returns all records when condition is empty", {
  result <- db$query("posts", "")
  expect_length(result, 2)
})

test_that("Querying a non-existent collection throws an error", {
  expect_error(db$query("comments", "id == 1"),
               "Error: Collection 'comments' does not exist.")
})

test_that("Querying with a non-existent key throws an error", {
  expect_error(db$query("posts", "nonexistent_key == 1"),
               "Error in evaluating condition")
})

test_that("Querying with an invalid syntax throws an error", {
  expect_error(db$query("posts", "views >"),
               "Error in evaluating condition")
})

test_that("Error handling works correctly", {
  expect_error(db$update("users", "id", 1, list(name = "John Doe")),
               "Error: Collection 'users' does not exist.")
  expect_error(db$delete("users", "id", 1),
               "Error: Collection 'users' does not exist.")

  expect_error(db$update("posts", "author", "Unknown", list(title = "Updated Title")),
               "Error: Key 'author' does not exist")
  expect_error(db$delete("posts", "author", "Unknown"),
               "Error: Key 'author' does not exist")
})

test_that("exists methods work as expected", {

  expect_true(db$exists_collection("posts"))
  expect_false(db$exists_collection("nonexistant"))

  expect_true(db$exists_key("posts", "title"))
  expect_true(db$exists_key("posts", "views"))
  expect_false(db$exists_key("posts", "nonexistant"))
  expect_error(db$exists_key("nonexistant", "key"))

  expect_true(db$exists_value("posts", "title", "LowDB in R"))
  expect_false(db$exists_value("posts", "title", "LowDB in nonexistant"))
  expect_error(db$exists_value("posts", "nonexistant", "LowDB in R"))

})

test_that("count method works as expected", {

  expect_error(db$count("nonexistant"))

  expect_equal(db$count("posts"), 2)

  db$insert("posts", list(id = 4, title = "R Advanced", views = 1100))
  db$insert("posts", list(id = 5, title = "Shiny for R", views = 2000))

  expect_equal(db$count("posts"), 4)

  db$delete("posts", "id", 5)

  expect_equal(db$count("posts"), 3)

})

test_that("transaction works as expected", {

  db$transaction(function() {

    db$insert("posts", list(id = 6, title = "Shiny for Python", views = 1000))
    db$insert("posts", list(id = 6, title = "Introduction to R"))

  })

  testthat::expect_equal(db$count("posts"), 5)

  testthat::expect_error({
    db$transaction(function() {

      db$insert("posts", list(id = 6, title = "Shiny for Python", views = 1000))
      db$insert("posts", list(id = 6, title = "Introduction to R", views = 200))

      stop("Random error. Rolling back expected")

    })
  })

  testthat::expect_equal(db$count("posts"), 5)

})


test_that("filter method works as expected", {

  expect_error(
    db$filter("posts", "not a function"),
    regexp = "Error: 'filter_fn' must be a function."
  )

  res <- db$filter("posts", function(x) {
    x$views >= 1000
  })

  expect_gte(res[[1]]$views, 1000)
  expect_gte(res[[2]]$views, 1000)

})

test_that("clear works as expected", {

  db$insert("readers", list(name = "Fodil", city = "Hamburg"))
  db$insert("readers", list(name = "Sun Goku", city = "Tokyo"))

  expect_equal(db$count("readers"), 2)

  db$clear("readers")

  expect_equal(db$count("readers"), 0)

})

test_that("drop works as expected", {

  db$insert("readers", list(name = "Fodil", city = "Hamburg"))
  db$insert("readers", list(name = "Sun Goku", city = "Tokyo"))

  expect_equal(db$count("readers"), 2)

  db$drop("readers")

  expect_error(db$count("readers"), regexp = "Collection 'readers' does not exist")

})

test_that("drop all works as expected", {

  db$drop_all()

  expect_equal(class(db$get_data()), "list")
  expect_equal(length(db$get_data()), 0)

})

unlink(test_db_file)
