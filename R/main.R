#' rlowdb: A Simple JSON-Based Database in R
#'
#' The `rlowdb` class provides a lightweight, JSON-based database solution
#' for storing and managing structured data in R.
#' It supports CRUD operations (Create, Read, Update, Delete)
#' and enables querying with custom functions.
#' @importFrom jsonlite fromJSON write_json
#' @importFrom purrr keep
#' @importFrom R6 R6Class
#' @importFrom rlang eval_tidy parse_expr
#' @export
rlowdb <- R6::R6Class(
  "rlowdb",
  public = list(

    #' @description Initialize the database, loading data from a JSON file.
    #' If the file does not exist, an empty database is created.
    #' @param file_path The path to the JSON file that stores the database.
    #' @examples
    #'   db <- rlowdb$new("database.json")
    initialize = function(file_path) {
      private$.file_path <- file_path
      private$.read_data()
    },

    #' @description Retrieve all stored data.
    #' @return A list containing all database records.
    #' @examples
    #'   db$get_data()
    get_data = function() {
      private$.data
    },

    #' @description Insert a new record into a specified collection.
    #' @param collection The collection name (a string).
    #' @param record A named list representing the record to insert.
    #' @examples
    #' \dontrun{
    #'   db$insert("users", list(id = 1, name = "Alice"))
    #' }
    #'
    insert = function(collection, record) {
      private$.ensure_key(collection)
      private$.data[[collection]] <- append(private$.data[[collection]], list(record))
      private$.write_data()
    },

    #' @description Find records in a collection that match a given key-value pair.
    #' @param collection The collection name (a string).
    #' @param key The field name to search for.
    #' @param value The value to match.
    #' @return A list of matching records. Returns an empty list if no match is found.
    #' @examples
    #' \dontrun{
    #'   db$find("users", "id", 1)
    #' }
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
    #' \dontrun{
    #'   db$update("users", "id", 1, list(name = "Alice Updated"))
    #' }
    #'
    update = function(collection, key, value, new_data) {
      index <- private$.find_index_by_key(collection, key, value)
      if (length(index) > 0) {
        for (i in index) {
          private$.data[[collection]][[i]] <- modifyList(private$.data[[collection]][[i]], new_data)
        }
        private$.write_data()
      } else {
        stop(sprintf("Error: No record found in '%s' where '%s' = '%s'.", collection, key, value))
      }
    },

    #' @description If a record exists, update it; otherwise, insert a new record.
    #' @param collection The collection name.
    #' @param key The field name to search for.
    #' @param value The value to match.
    #' @param new_data A named list containing the updated data.
    #' @examples
    #' \dontrun{
    #'   db$upsert("users", "id", 1, list(name = "Alice Updated"))
    #' }
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
    #' \dontrun{
    #'   db$delete("users", "id", 1)
    #' }
    #'
    delete = function(collection, key, value) {
      index <- private$.find_index_by_key(collection, key, value)
      if (length(index) > 0) {
        private$.data[[collection]] <- private$.data[[collection]][-index]
        private$.write_data()
      } else {
        stop(sprintf("Error: No record found in '%s' where '%s' = '%s'.", collection, key, value))
      }
    },

    #' @description Query a collection using a condition string.
    #'
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
    #'
    #' \dontrun{
    #'   db <- rlowdb$new("db.json")
    #'   db$insert("posts", list(id = 1, title = "LowDB in R", views = 100))
    #'   db$insert("posts", list(id = 2, title = "Data Management", views = 250))
    #'   db$insert("posts", list(id = 3, title = "Advanced R", views = 300))
    #'
    #'   # Query posts with views > 200 AND id > 2
    #'   db$query("posts", "views > 200 & id > 2")
    #'
    #'   # Query posts with views > 100 OR id == 1
    #'   db$query("posts", "views > 100 | id == 1")
    #'
    #'   # Query all posts (no condition)
    #'   db$query("posts", "")
    #' }
    #'
    query = function(collection, condition = NULL) {
      if (!collection %in% names(private$.data)) {
        stop(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      records <- private$.data[[collection]]

      if (is.null(condition) || condition == "") {
        return(records)
      }

      filtered_records <- purrr::keep(records, function(record) {
        tryCatch({
          rlang::eval_tidy(rlang::parse_expr(condition), data = record)
        }, error = function(e) {
          stop(sprintf("Error in evaluating condition: '%s'", condition))
        })
      })

      return(filtered_records)
    },

    #' @description Just like DROP TABLE in SQL, drops a complete collection.
    #' @param collection The collection name.
    #' @examples
    #' \dontrun{
    #'   db$drop("users")
    #' }
    #'
    drop = function(collection) {

      if (!collection %in% names(private$.data)) {
        stop(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      private$.data[[collection]] <- NULL

      private$.write_data()

    },

    #' @description Drop all the collections available in your JSON file DB
    #' @examples
    #' \dontrun{
    #'   db$drop_all()
    #' }
    #'
    drop_all = function() {

      for (collection in names(private$.data)) {
        private$.data[[collection]] <- NULL
      }

      private$.write_data()

    },

    #' @description Removes all records from a collection without deleting the collection itself
    #' @param collection the collection name
    #' @examples
    #' \dontrun{
    #'   db$clear("users")
    #' }
    #'

    clear = function(collection) {
      if (!collection %in% names(private$.data)) {
        stop(sprintf("Error: Collection '%s' does not exist.", collection))
      }
      private$.data[[collection]] <- list()
      private$.write_data()
    },

    #' @description Count the number of records in a collection
    #' @param collection the collection name
    #' @return numeric
    #' @examples
    #' \dontrun{
    #'   db$count("users")
    #' }
    #'
    count = function(collection) {

      if (!collection %in% names(private$.data)) {
        stop(sprintf("Error: Collection '%s' does not exist.", collection))
      }

      count_collection <- length(private$.data[[collection]])

      count_collection

    },

    #' @description List the available collections
    #' @return character
    #' @examples
    #' \dontrun{
    #'   db$list_collections()
    #' }
    #'
    list_collections = function() {

      collection_names <- names(private$.data)

      collection_names

    },

    #' @description Check if a collection exists.
    #' @param collection The collection name
    #' @return TRUE if the collection exists, FALSE otherwise
    #' @examples
    #' \dontrun{
    #'   db$exists_collection("users")
    #' }
    #'
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
    #' \dontrun{
    #'   db$exists_key("users", "name")
    #' }
    #'
    exists_key = function(collection, key) {

      if (!collection %in% names(private$.data)) {
        stop(sprintf("Error: Collection '%s' does not exist.", collection))
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
    #' \dontrun{
    #'   db$exists_value("users", "id", 1)
    #' }
    #'
    exists_value = function(collection, key, value) {

      exists_val <- FALSE
      index <- private$.find_index_by_key(collection, key, value)

      if (length(index) > 0) {
        exists_val <- TRUE
      }

      exists_val
    }
  ),

  private = list(

    .file_path = NULL,
    .data = NULL,

    .read_data = function() {
      if (file.exists(private$.file_path)) {
        private$.data <- jsonlite::fromJSON(private$.file_path, simplifyVector = FALSE)
      } else {
        private$.data <- list()
      }
    },

    .write_data = function() {
      jsonlite::write_json(private$.data, private$.file_path, pretty = TRUE, auto_unbox = TRUE)
    },

    .ensure_key = function(key) {
      if (!key %in% names(private$.data)) {
        private$.data[[key]] <- list()
      }
    },

    .find_index_by_key = function(collection, key, value) {
      if (!collection %in% names(private$.data)) {
        stop(sprintf("Error: Collection '%s' does not exist.", collection))
      }
      if (!any(sapply(private$.data[[collection]], function(item) key %in% names(item)))) {
        stop(sprintf("Error: Key '%s' does not exist in collection '%s'.", key, collection))
      }
      which(sapply(private$.data[[collection]], function(item) item[[key]] == value))
    }
  )
)









