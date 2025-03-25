library(testthat)
library(jsonlite)

test_that("Object is not created without a json file", {
  test_db_file <- tempfile(fileext = ".csv")
  expect_error({
    db <- rlowdb$new(test_db_file)
  },
  regexp = "is not of JSON format")
})

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

test_that("Sample records works as expected", {

  expect_error(
    db$sample_records(collection = "non_existant", n = 1),
    regexp = "Collection 'non_existant' does not exist"
  )

  expect_warning(
    db$sample_records(collection = "posts", n = 3),
    regexp = "Returning all records"
  )

  res1 <- db$sample_records(collection = "posts", n = 1, seed = 123)
  res1_bis <- db$sample_records(collection = "posts", n = 1, seed = 123)

  expect_equal(res1, res1_bis)

  res2 <- db$sample_records(collection = "posts", n = 2, seed = 123)
  expect_equal(length(res1), 1)
  expect_equal(length(res2), 2)

  res10 <- db$sample_records(collection = "posts", n = 10, seed = 123, replace = TRUE)
  expect_equal(length(res10), 10)

})

test_that("get_collection_data works as expected", {

  res <- db$get_data_collection("posts")

  expect_equal(length(res), 2)
  el <- res[[1]]
  expect_equal(names(el), c("id", "title", "views"))

  expect_error(
    object = db$get_data_collection("non_existant"),
    regexp = "Collection 'non_existant' does not exist"
  )

})

test_that("get_data_key works as expected", {

  res <- db$get_data_key("posts", "title")

  expect_equal(length(res), 2)
  expect_equal(res, c("LowDB in R", "Data Management"))

  expect_error(
    object = db$get_data_key("posts", "non_existant"),
    regexp = "Key 'non_existant' does not exist in collection 'posts'"
  )
})

test_that("auto_commit works as expected", {

  db$set_auto_commit(auto_commit = FALSE)
  db$insert("posts", list(id = 55, title = "LowDB in R", views = 100))

  expect_equal(db$count("posts"), 3)

  db$restore(test_db_file)

  expect_equal(db$count("posts"), 2)

  db$insert("posts", list(id = 55, title = "LowDB in R", views = 100))

  db$commit()

  db$restore(test_db_file)

  expect_equal(db$count("posts"), 3)

  db$set_auto_commit(auto_commit = TRUE)

  db$delete("posts", "id", 55)

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

test_that("count_value works as expected", {

  db$insert("posts", list(id = 6, title = "Introduction to R", views = 200))
  count <- db$count_values("posts", key = "title")

  count_chr <- as.character(count)

  expect_equal(count_chr, c("1", "2", "1", "1", "1"))

  db$insert("posts", list(id = 6, title = "Introduction to R", views = 200))
  db$insert("posts", list(id = 6, title = "Shiny for Python", views = 200))
  count <- db$count_values("posts", key = "title")

  count_chr <- as.character(count)

  expect_equal(count_chr, c("1", "3", "1", "1", "2"))

})

test_that("list and rename collection work as expected", {

  collection <- db$list_collections()

  expect_equal(collection, "posts")

  expect_length(collection, 1)

  db$rename_collection("posts", "books")

  collection <- db$list_collections()

  expect_equal(collection, "books")

  expect_length(collection, 1)

  expect_error(
    db$rename_collection("nonexistant", "new"),
    regexp = "Collection 'nonexistant' does not exist"
  )

})

test_that("list_keys works as expected", {

  keys <- db$list_keys("books")

  expect_equal(
    keys,
    c("id", "title", "views")
  )

  db$insert("books", list(
    id = 32,
    title = "Introduction to R",
    views = 200,
    license = "MIT"
  ))

  keys <- db$list_keys("books")

  expect_equal(
    keys,
    c("id", "title", "views", "license")
  )
})

test_that("insert_default_values works correctly", {

  db$bulk_insert("users", list(
    list(name = "Alice", age = 30),
    list(name = "Bob"),
    list(name = "Charlie", age = 25, role = "admin")
  ))

  keys <- db$list_keys("users")

  expect_equal(keys, c("name", "age", "role"))

  db$insert_default_values("users", list(role = "guest", active = TRUE), replace_existing = FALSE)

  keys <- db$list_keys("users")

  expect_equal(keys, c("role", "active", "name", "age"))

  users <- db$get_data()[["users"]]

  alice <- users[[1]]
  bob <- users[[2]]
  charlie <- users[[3]]

  expect_true(alice$role == "guest")
  expect_true(alice$active == TRUE)

  expect_true(bob$role == "guest")
  expect_true(bob$active == TRUE)

  expect_true(charlie$role == "admin")
  expect_true(charlie$active == TRUE)

  db$insert_default_values("users", list(role = "guest", active = TRUE), replace_existing = TRUE)

  users <- db$get_data()[["users"]]

  charlie <- users[[3]]

  expect_true(charlie$role == "guest")

  db$insert_default_values("users", list(active = FALSE), replace_existing = FALSE)

  users <- db$get_data()[["users"]]

  expect_true(users[[1]]$active == TRUE)
  expect_true(users[[2]]$active == TRUE)
  expect_true(users[[3]]$active == TRUE)

  db$insert("users", list(name = "David"))

  db$insert_default_values("users", list(role = "guest", active = TRUE), replace_existing = FALSE)

  users <- db$get_data()[["users"]]

  expect_true(users[[4]]$role == "guest")
  expect_true(users[[4]]$active == TRUE)
  expect_true(users[[4]]$name == "David")

})

test_that("default_values works as expected", {

  db_without_defaults <-  rlowdb$new("db2.json")

  db_with_defaults <- rlowdb$new("db1.json", default_values = list(
    "users" = list("active" = TRUE),
    "readers" = list("minimal_age" = 18)
  ))

  db_without_defaults$insert("users", list(id = 1, name = "Alice"))

  db_with_defaults$insert("users", list(id = 1, name = "Alice"))

  expect_equal(db_without_defaults$list_keys("users"), c("id", "name"))

  expect_equal(db_with_defaults$list_keys("users"), c("active", "id", "name"))

  expect_false(db_with_defaults$exists_collection("readers"))

  db_with_defaults$insert("readers", list(id = 1, name = "Fodil", age = 33))

  expected_keys <- c("minimal_age", "id", "name", "age")

  expect_equal(db_with_defaults$list_keys("readers"), expected_keys)

  unlink("db1.json")
  unlink("db2.json")

})

test_that("clone_collection works as expected", {

  db$clone_collection(from = "users", "users_backup")

  expect_equal(
    db$list_collections(),
    c("books", "users", "users_backup")
  )

  expect_equal(
    db$get_data_collection("users"),
    db$get_data_collection("users_backup")
  )

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



