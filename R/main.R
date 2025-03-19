#' rlowdb: A Simple JSON-Based Database in R
#'
#' @description
#' The `rlowdb` class provides a lightweight, JSON-based database solution
#' for storing and managing structured data in R.
#' It supports CRUD operations (Create, Read, Update, Delete)
#' and enables querying with custom functions.
#' @importFrom jsonlite fromJSON write_json
#' @importFrom purrr keep safely map
#' @importFrom R6 R6Class
#' @importFrom rlang eval_tidy parse_expr abort
#' @importFrom cli cli_alert_success cli_text cli_alert_info
#' @export
rlowdb <- R6::R6Class(
  "rlowdb",
  public = list(

    #' @description Initialize the database, loading data from a JSON file.
    #' If the file does not exist, an empty database is created.
    #' @param file_path The path to the JSON file that stores the database.
    #' @param auto_commit whether to update the DB automatically each time
    #' there's an insertion, an update or a deletion. Defaults to TRUE.s
    #' Note that you can use the `commit` method to update the DB manually.
    #' @param verbose If TRUE, will print informative messages to the console.
    #' Defaults to FALSE
    initialize = function(file_path, auto_commit = TRUE, verbose = FALSE) {

      file_extension <- tolower(tools::file_ext(file_path))

      if (!file_extension == "json") {
        rlang::abort(
          glue::glue(
            "{file_path} is not of JSON format"
          )
        )
      }

      private$.file_path <- file_path
      private$.auto_commit <- auto_commit
      private$.verbose <- verbose
      private$.read_data()
    },

    #' @description Update the DB with the operated changes.
    commit = function() {
      private$.write_data()
    },

    #' @description Retrieve all stored data.
    #' @return A list containing all database records.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(id = 1, name = "Alice"))
    #' db$get_data()
    #' unlink("database.json")
    #
    get_data = function() {
      private$.data
    },

    #' @description Insert a new record into a specified collection.
    #' @param collection The collection name (a string).
    #' @param record A named list representing the record to insert.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(id = 1, name = "Alice"))
    #' unlink("database.json")
    #'
    insert = function(collection, record) {
      if (!is.list(record) || is.null(names(record)) || !all(nzchar(names(record)))) {
        rlang::abort("Error: 'record' must be a named list with valid field names.")
      }
      private$.ensure_key(collection)
      private$.data[[collection]] <- append(private$.data[[collection]], list(record))

      if (private$.verbose) {
        cli::cli_alert_success(
          "record successfully inserted into collection '{collection}'"
        )
      }

      if (private$.auto_commit) {
        private$.write_data()
      }

    },

    #' @description Find records in a collection that match a given key-value pair.
    #' @param collection The collection name (a string).
    #' @param key The field name to search for.
    #' @param value The value to match.
    #' @return A list of matching records. Returns an empty list if no match is found.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(id = 1, name = "Alice"))
    #' db$find("users", "id", 1)
    #' unlink("database.json")
    #'
    find = function(collection, key, value) {
      index <- private$.find_index_by_key(collection, key, value)
      if (length(index) > 0) {
        return(private$.data[[collection]][index])
      } else {
        message(sprintf("No record found in '%s' where '%s' = '%s'.", collection, key, value))
        return(list())
      }
    },

    #' @description Update existing records in a collection.
    #' @param collection The collection name.
    #' @param key The field name to search for.
    #' @param value The value to match.
    #' @param new_data A named list containing the updated data.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(id = 1, name = "Alice"))
    #' db$update("users", "id", 1, list(name = "Alice Updated"))
    #' unlink("database.json")
    #'
    update = function(collection, key, value, new_data) {
      index <- private$.find_index_by_key(collection, key, value)
      if (length(index) > 0) {
        for (i in index) {
          private$.data[[collection]][[i]] <- modifyList(private$.data[[collection]][[i]], new_data)
        }

        if (private$.verbose) {
          cli::cli_alert_success(
            "Value {value} successfully updated with {new_data}"
          )
        }

        if (private$.auto_commit) {
          private$.write_data()
        }

      } else {
        rlang::abort(sprintf("Error: No record found in '%s' where '%s' = '%s'.", collection, key, value))
      }
    },

    #' @description If a record exists, update it; otherwise, insert a new record.
    #' Note that in order to use the method, the 'collection' has to
    #' exist
    #' @param collection The collection name.
    #' @param key The field name to search for.
    #' @param value The value to match.
    #' @param new_data A named list containing the updated data.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(id = 100, name = "Coconut"))
    #' db$upsert("users", "id", 1, list(name = "Alice Updated"))
    #' unlink("database.json")
    #'
    upsert = function(collection, key, value, new_data) {
      if (self$exists_value(collection, key, value)) {
        self$update(collection, key, value, new_data)
      } else {
        record <- c(setNames(list(value), key), new_data)
        self$insert(collection, record)
      }
    },

    #' @description Delete records from a collection that match a given key-value pair.
    #' @param collection The collection name.
    #' @param key The field name to search for.
    #' @param value The value to match.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(id = 1, name = "Alice"))
    #' db$delete("users", "id", 1)
    #' db$get_data()
    #' unlink("database.json")
    #'
    delete = function(collection, key, value) {
      index <- private$.find_index_by_key(collection, key, value)
      if (length(index) > 0) {
        private$.data[[collection]] <- private$.data[[collection]][-index]

        if (private$.verbose) {
          cli::cli_alert_success(
            "Value {value} successfully deleted from key '{key}': collection '{collection}'"
          )
        }

        if (private$.auto_commit) {
          private$.write_data()
        }
      } else {
        rlang::abort(sprintf("Error: No record found in '%s' where '%s' = '%s'.", collection, key, value))
      }
    },

    #' @description
    #' Query a collection using a condition string.
    #' This function allows filtering records from a collection using a condition
    #' string that is evaluated dynamically. The condition supports multiple logical
    #' expressions using standard R operators (e.g., `>`, `<`, `==`, `&`, `|`).
    #'
    #' @param collection The collection name (a string).
    #' @param condition A string representing a logical condition for filtering records.
    #'   - Supports comparisons (`>`, `<`, `>=`, `<=`, `==`, `!=`).
    #'   - Allows logical operators (`&` for AND, `|` for OR).
    #'   - Example: `"views > 200 & id > 2"`.
    #'   - If `NULL` or an empty string (`""`), returns all records.
    #'
    #' @return A list of records that satisfy the condition. If no records match, returns an empty list.
    #'
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("posts", list(id = 1, title = "LowDB in R", views = 100))
    #' db$insert("posts", list(id = 2, title = "Data Management", views = 250))
    #' db$insert("posts", list(id = 3, title = "Advanced R", views = 300))
    #'
    #' # Query posts with views > 200 AND id > 2
    #' db$query("posts", "views > 200 & id > 2")
    #'
    #' # Query posts with views > 100 OR id == 1
    #' db$query("posts", "views > 100 | id == 1")
    #'
    #' # Query all posts (no condition)
    #' db$query("posts", "")
    #'
    #' unlink("database.json")
    query = function(collection, condition = NULL) {
      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      records <- private$.data[[collection]]

      if (is.null(condition) || condition == "") {
        return(records)
      }

      filtered_records <- purrr::keep(records, function(record) {
        tryCatch({
          rlang::eval_tidy(rlang::parse_expr(condition), data = record)
        }, error = function(e) {
          rlang::abort(sprintf("Error in evaluating condition: '%s'", condition))
        })
      })

      return(filtered_records)
    },

    #' @description
    #' Filter Records Using a Custom Function
    #' This method applies a user-defined function to filter records in a specified collection.
    #' The function should take a record as input and return `TRUE` for records that should be included
    #' in the result and `FALSE` for records that should be excluded.
    #'
    #' @param collection A character string specifying the name of the collection.
    #' @param filter_fn A function that takes a record (a list) as input and returns `TRUE` or `FALSE`.
    #'
    #' @return A list of records that satisfy the filtering condition.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("users", list(name = "Gamma", age = 36))
    #' # Find users older than 30
    #' db$filter("users", function(record) record$age > 30)
    #' unlink("database.json")

    filter = function(collection, filter_fn) {

      if (!is.function(filter_fn)) {
        rlang::abort("Error: 'filter_fn' must be a function.")
      }

      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      safe_filter_fn <- purrr::safely(filter_fn, otherwise = FALSE)

      purrr::keep(private$.data[[collection]], function(x) {
        result <- safe_filter_fn(x)$result
        isTRUE(result)
      })

    },

    #' @description Just like DROP TABLE in SQL, drops a complete collection.
    #' @param collection The collection name.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$drop("users")
    #' db$get_data()
    #' unlink("database.json")
    drop = function(collection) {

      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      private$.data[[collection]] <- NULL

      if (private$.verbose) {
        cli::cli_alert_success("'{collection}' successfully droped")
      }

      if (private$.auto_commit) {
        private$.write_data()
      }

    },

    #' @description Drop all the collections available in your JSON file DB
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("consumers", list(name = "Teta", age = 22))
    #' db$drop_all()
    #' db$get_data()
    #' unlink("database.json")
    drop_all = function() {

      for (collection in names(private$.data)) {
        private$.data[[collection]] <- NULL
      }

      if (private$.verbose) {
        cli::cli_alert_success("All collection have been dropped")
      }

      if (private$.auto_commit) {
        private$.write_data()
      }

    },

    #' @description Removes all records from a collection without deleting the collection itself
    #' @param collection the collection name
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("consumers", list(name = "Teta", age = 22))
    #' db$clear("users")
    #' db$get_data()
    #' unlink("database.json")

    clear = function(collection) {
      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }
      private$.data[[collection]] <- list()

      if (private$.verbose) {
        cli::cli_alert_success("'{collection}' collection successfully cleared")
      }

      if (private$.auto_commit) {
        private$.write_data()
      }
    },

    #' @description Count the number of records in a collection
    #' @param collection the collection name
    #' @return numeric
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("users", list(name = "Gamma", age = 36))
    #' db$count("users")
    #' unlink("database.json")
    count = function(collection) {

      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      count_collection <- length(private$.data[[collection]])

      count_collection

    },

    #' @description List the available collections
    #' @return character
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("consumers", list(name = "Teta", age = 22))
    #' db$list_collections()
    #' unlink("database.json")
    list_collections = function() {

      collection_names <- names(private$.data)

      collection_names

    },

    #' @description Check if a collection exists.
    #' @param collection The collection name
    #' @return TRUE if the collection exists, FALSE otherwise
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("consumers", list(name = "Teta", age = 22))
    #' db$exists_collection("users")
    #' unlink("database.json")
    exists_collection = function(collection) {

      exists_collection <- FALSE

      if (collection %in% names(private$.data)) {
        exists_collection <- TRUE
      }

      exists_collection

    },

    #' @description Check if a key exists within a specific collection.
    #' @param collection The collection name
    #' @param key The key name
    #' @return TRUE if the key exists, FALSE otherwise
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("consumers", list(name = "Teta", age = 22))
    #' db$exists_key("users", "name")
    #' unlink("database.json")
    exists_key = function(collection, key) {

      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      exists_key <- any(
        sapply(private$.data[[collection]], function(item) {
          key %in% names(item)
        })
      )

      exists_key

    },

    #' @description Check if a value exists within a specific collection/key combination.
    #' @param collection The collection name
    #' @param key The key name
    #' @param value The value to look for
    #' @return TRUE if the value exists, FALSE otherwise
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$insert("consumers", list(name = "Teta", age = 22))
    #' db$exists_value("users", "name", "Delta")
    #' unlink("database.json")
    exists_value = function(collection, key, value) {

      exists_val <- FALSE
      index <- private$.find_index_by_key(collection, key, value)

      if (length(index) > 0) {
        exists_val <- TRUE
      }

      exists_val
    },

    #' @description
    #' Perform a Transaction with Rollback on Failure
    #'
    #' This method executes a sequence of operations as a transaction.
    #' If any operation fails, it rolls back all changes to maintain data integrity.
    #' @param transaction_fn A function that performs operations on `self`. It should not return a value.
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(name = "Delta", age = 25))
    #' db$count("users")
    #' db$transaction(function() {
    #'   db$insert("users", list(name = "Zlatan", age = 40))
    #'   db$insert("users", list(name = "Neymar", age = 28))
    #'   # if an error is raised, a rollback will happen and
    #'   # the records won't be inserted
    #' })
    #' db$count("users")
    #' unlink("database.json")

    transaction = function(transaction_fn) {
      if (!is.function(transaction_fn)) {
        rlang::abort("Error: 'transaction_fn' must be a function.")
      }
      original_data <- private$.data
      tryCatch({
        transaction_fn()

        if (private$.verbose) {
          cli::cli_alert_success("Transaction successfully operated")
        }

        if (private$.auto_commit) {
          private$.write_data()
        }
      }, error = function(e) {
        private$.data <- original_data
        rlang::abort(sprintf("Transaction failed: %s", e$message))
      })
    },

    #' @description Load a JSON backup and replace the current database.
    #' @param backup_path The path of the backup JSON file.

    restore = function(backup_path) {

      if (!file.exists(backup_path)) {
        rlang::abort("Error: Backup file does not exist.")
      }

      private$.data <- jsonlite::fromJSON(backup_path, simplifyVector = FALSE)

      if (private$.verbose) {
        cli::cli_alert_success("Backup successfully restored from {backup_path}")
      }

      if (private$.auto_commit) {
        private$.write_data()
      }
    },

    #' Allow users to quickly backup their database.
    #' @param backup_path The path of the backup JSON file

    backup = function(backup_path) {
      jsonlite::write_json(private$.data, backup_path, pretty = TRUE, auto_unbox = TRUE)
      if (private$.verbose) {
        cli::cli_alert_success("Backup successfully created at {backup_path}")
      }
    },

    #' @description
    #' Search Records in a Collection
    #'
    #' This method searches for records in a collection where a specified key's value
    #' contains a given search term.
    #'
    #' @param collection A character string specifying the name of the collection.
    #' @param key A character string specifying the field to search within.
    #' @param term A character string specifying the term to search for.
    #' @param ignore.case A logical value indicating whether the search should be case-insensitive (default: `FALSE`).
    #'
    #' @return A list of matching records. Returns an empty list if no matches are found.
    #'
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$insert("users", list(id = 1, name = "Alice"))
    #' db$insert("users", list(id = 2, name = "Bob"))
    #' db$insert("users", list(id = 3, name = "alice"))
    #'
    #' # Case-sensitive search
    #' db$search("users", "name", "Alice", ignore.case = FALSE)
    #'
    #' # Case-insensitive search
    #' db$search("users", "name", "alice", ignore.case = TRUE)
    #' unlink("database.json")
    search = function(collection, key, term, ignore.case = FALSE) {
      if (!self$exists_collection(collection)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      if (!self$exists_key(collection, key)) {
        rlang::abort(sprintf("Error: Key '%s' does not exist in collection '%s'.", key, collection))
      }

      matching_records <- purrr::keep(private$.data[[collection]], function(item) {

        value <- as.character(item[[key]])
        term <- as.character(term)

        grepl(term, value, ignore.case = TRUE)

      })

      return(matching_records)
    },

    #' @description
    #' Insert Multiple Records into a Collection
    #'
    #' This method inserts multiple records into a specified collection at once.
    #' Each record should be a named list representing an entry in the collection.
    #'
    #' @param collection A character string specifying the name of the collection.
    #' @param records A list of named lists, where each named list represents a record to insert.
    #'
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$bulk_insert("users", list(
    #'   list(id = 1, name = "Alice", age = 25),
    #'   list(id = 2, name = "Bob", age = 32),
    #'   list(id = 3, name = "Charlie", age = 40)
    #' ))
    #' db$count("users")
    #' unlink("database.json")
    bulk_insert = function(collection, records) {

      if (!is.list(records) || length(records) == 0) {
        rlang::abort("Error: 'records' must be a non-empty list of named lists.")
      }

      valid_records <- sapply(records, function(record) {
        is.list(record) && !is.null(names(record)) && all(nzchar(names(record)))
      })

      if (!all(valid_records)) {
        rlang::abort("Error: Each record must be a named list with valid field names.")
      }

      if (is.null(private$.data[[collection]])) {
        private$.data[[collection]] <- list()
      }

      private$.data[[collection]] <- c(private$.data[[collection]], records)

      if (private$.verbose) {
        cli::cli_alert_success(
          "Bulk insertion successfull"
        )
      }

      if (private$.auto_commit) {
        private$.write_data()
      }

    },

    #' @description
    #' Provides some useful information about the database
    #'
    status = function() {

      db_exists <- FALSE

      if (file.exists(private$.file_path)) {
        db_exists <- TRUE
      }

      cli::cli_text("{.strong - database path:} {private$.file_path}")
      cli::cli_text("{.strong - database exists:} {db_exists} ")
      cli::cli_text("{.strong - auto_commit:} {private$.auto_commit}")
      cli::cli_text("{.strong - verbose:} {private$.verbose}")

    },

    #' @description
    #' Set the auto_commit value
    #' @param auto_commit TRUE will update automatically the JSON
    #' by each insertion/update/delete. If FALSE, you'll need to
    #' use the commit method whenever you want to commit your changes
    #' to the JSON DB.

    set_auto_commit = function(auto_commit) {
      private$.auto_commit <- auto_commit
    },
    #' @description
    #' Set the verbose value.
    #' @param verbose If TRUE, informative messages will be printed
    #' to the console.
    set_verbose = function(verbose) {
      private$.verbose = verbose
    },

    #' @description
    #' Allows you to rename an existing collection in the database.
    #' It checks if the specified collection exists before attempting to rename it.
    #' @param collection_name A character string representing the current name of the collection to be renamed.
    #' @param new_collection_name A character string representing the new name for the collection.
    #'
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$bulk_insert("users", list(
    #'   list(id = 1, name = "Alice", age = 25),
    #'   list(id = 2, name = "Bob", age = 32),
    #'   list(id = 3, name = "Charlie", age = 40)
    #' ))
    #' db$list_collections()
    #' db$rename_collection("users", "customers")
    #' db$list_collections()
    #' unlink("database.json")
    #'
    rename_collection = function(collection_name, new_collection_name) {
      if (!collection_name %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection_name))
      }

      if (new_collection_name %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' already exists.", new_collection_name))
      }

      private$.data[[new_collection_name]] <- private$.data[[collection_name]]
      private$.data[[collection_name]] <- NULL

      if (private$.verbose) {
        cli::cli_alert_success("collection '{collection_name}' successfully renamed to '{new_collection_name}'")
      }

      if (private$.auto_commit) {
        private$.write_data()
      }
    },

    #' @description
    #' Retrieves the names (keys) of all keys within a given collection.
    #'
    #' @param collection The collection name
    #'
    #' @return A character vector containing the unique keys (field names) present across all records in the collection.
    #'
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$bulk_insert("users", list(
    #'   list(id = 1, name = "Alice", age = 25),
    #'   list(id = 2, name = "Bob", age = 32),
    #'   list(id = 3, name = "Charlie")
    #' ))
    #' db$list_keys("users")
    #' unlink("database.json")
    #'
    list_keys = function(collection) {
      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      keys <- unique(unlist(purrr::map(private$.data[[collection]], names)))

      return(keys)
    },

    #' @description
    #' Count Occurrences of a Key's Values in a Collection
    #'
    #' @param collection The collection name
    #' @param key The key name
    #' @return A table (a frequency count) of the values associated with the specified key,
    #'   showing the number of occurrences of each unique value. If the key does not exist,
    #'   an error is thrown.
    #'
    #' @examples
    #' db <- rlowdb$new("database.json")
    #' db$bulk_insert("users", list(
    #'   list(id = 1, name = "Alice", age = 25),
    #'   list(id = 2, name = "Bob", age = 32),
    #'   list(id = 3, name = NA),
    #'   list(id = 4, name = NA)
    #' ))
    #' db$count_values("users", "name")
    #' unlink("database.json")
    count_values = function(collection, key) {

      if (!self$exists_collection(collection)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      if (!self$exists_key(collection, key)) {
        rlang::abort(sprintf("Error: Key '%s' does not exist in any record of the collection '%s'.", key, collection))
      }

      count <- sapply(private$.data[[collection]], function(x) {
        if (is.null(x[[key]]) || is.na(x[[key]])) {
          return(NA)
        } else {
          return(x[[key]])
        }
      })

      table(count, useNA = "ifany")
    }

  ),

  private = list(
    .file_path = NULL,
    .auto_commit = NULL,
    .verbose = NULL,
    .data = NULL,

    .read_data = function() {
      if (file.exists(private$.file_path)) {
        private$.data <- jsonlite::fromJSON(private$.file_path, simplifyVector = FALSE)

        if (private$.verbose) {
          cli::cli_alert_info(
            "JSON DB already available, reading from {private$.file_path}"
          )
        }

      } else {
        private$.data <- list()

        if (private$.verbose) {
          cli::cli_alert_info(
            "JSON DB not found, initializing empty data object"
          )
        }
      }
    },

    .write_data = function() {
      jsonlite::write_json(private$.data, private$.file_path, pretty = TRUE, auto_unbox = TRUE)
      if (private$.verbose) {
        cli::cli_alert_success("{basename(private$.file_path)} successfully updated")
      }
    },

    .ensure_key = function(key) {
      if (!key %in% names(private$.data)) {
        private$.data[[key]] <- list()
      }
    },

    .find_index_by_key = function(collection, key, value) {
      if (!collection %in% names(private$.data)) {
        rlang::abort(sprintf("Error: Collection '%s' does not exist.", collection))
      }
      if (!any(sapply(private$.data[[collection]], function(item) key %in% names(item)))) {
        rlang::abort(sprintf("Error: Key '%s' does not exist in collection '%s'.", key, collection))
      }
      which(sapply(private$.data[[collection]], function(item) item[[key]] == value))
    }
  )
)

