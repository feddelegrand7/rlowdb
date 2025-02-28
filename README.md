
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rlowdb

<!-- badges: start -->

<!-- badges: end -->

`rlowdb` is a lightweight, JSON-based database for R, inspired by
[LowDB](https://github.com/typicode/lowdb) from JavaScript. It provides
a simple and efficient way to store, retrieve, update, and delete
structured data without the need for a full database system.

## Features

- **Lightweight & File-Based**: Uses JSON for persistent storage.
- **Easy-to-Use API**: Supports CRUD operations (Create, Read, Update,
  Delete).
- **Flexible Queries**: Allows filtering with expressive conditions.
- **No External Dependencies**: No need for SQL or additional database
  software.

## Installation

`rlowdb` is not yet available on CRAN, but you can install it from
GitHub:

``` r
devtools::install_github("feddelegrand7/rlowdb")
```

## Usage

### Initializing the Database

To start using \`rlowdb\`\`, create a new database instance by
specifying a JSON file:

``` r
library(rlowdb)
db <- rlowdb$new("database.json")
```

### Inserting Data

The `insert` method takes two parameters, a `collection` and a `record`,
think of the `collection` parameter as a `table` in the **SQL** world.
Think of the `record` parameter as a `list` of names, each name/value
pair representing a specific column and it’s value.

Add records to a collection:

``` r
db$insert(
  collection = "users", 
  record = list(id = 1, name = "Alice", age = 30)
)
db$insert(
  collection = "users", 
  record = list(id = 2, name = "Bob", age = 25)
)
```

### Retrieving Data

Get all stored data:

``` r
db$get_data()
```

Find a specific record:

``` r
db$find(collection = "users", key = "id", value = 1)
```

### Updating Records

Modify existing records:

``` r
db$update(
  collection = "users", 
  key = "id", 
  value = 1, 
  new_data = list(age = 31)
)
```

### Deleting Records

``` r
db$delete(collection = "users", key = "id", value = 2) 
```

### Querying Data

Find users older than 25:

``` r
db$query(collection = "users", condition = "age > 25")
```

Query with multiple conditions:

``` r
db$query(collection = "users", condition = "age > 25 & id > 1")
```

### Error Handling

`rlowdb` provides error handling for common issues. For example,
attempting to update a collection that does not exist will result in an
informative error:

``` r
db$update(
  collection = "nonexistant", 
  key = "id",
  value = 1, 
  new_data = list(age = 40)
)  
```

### Future Features

- Support for nested data structures.
- More advanced query capabilities.
- Compatibility with alternative file formats (e.g., CSV, SQLite).

## Code of Conduct

Please note that the ralger project is released with a [Contributor Code
of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
