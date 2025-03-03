
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rlowdb

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/feddelegrand7/rlowdb/branch/main/graph/badge.svg)](https://app.codecov.io/gh/feddelegrand7/rlowdb?branch=main)
[![R-CMD-check](https://github.com/feddelegrand7/rlowdb/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/feddelegrand7/rlowdb/actions/workflows/R-CMD-check.yaml)
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
db <- rlowdb$new("DB.json")
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

db$insert(
  collection = "users", 
  record = list(id = 3, name = "Alice", age = 30)
)
```

### Retrieving Data

Get all stored data:

``` r
db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 30
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
```

Find a specific record:

``` r
db$find(collection = "users", key = "id", value = 1)
#> [[1]]
#> [[1]]$id
#> [1] 1
#> 
#> [[1]]$name
#> [1] "Alice"
#> 
#> [[1]]$age
#> [1] 30
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

db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 31
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
```

The `upsert` methods allows you to update a record if it exists,
otherwise, it will be inserted:

``` r
db$upsert(
  collection = "users", 
  key = "id", 
  value = 1, 
  new_data = list(age = 25)
)

db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 25
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
```

``` r
db$upsert(
  collection = "users", 
  key = "id", 
  value = 100, 
  new_data = list(age = 25)
)

db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 25
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
#> 
#> 
#> $users[[4]]
#> $users[[4]]$id
#> [1] 100
#> 
#> $users[[4]]$age
#> [1] 25
```

### Deleting Records

``` r
db$delete(collection = "users", key = "id", value = 100) 

db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 25
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
```

### Querying Data

Find users older than 25:

``` r
db$query(collection = "users", condition = "age > 25")
#> [[1]]
#> [[1]]$id
#> [1] 3
#> 
#> [[1]]$name
#> [1] "Alice"
#> 
#> [[1]]$age
#> [1] 30
```

Query with multiple conditions:

``` r
db$query(collection = "users", condition = "age > 20 & id > 1")
#> [[1]]
#> [[1]]$id
#> [1] 2
#> 
#> [[1]]$name
#> [1] "Bob"
#> 
#> [[1]]$age
#> [1] 25
#> 
#> 
#> [[2]]
#> [[2]]$id
#> [1] 3
#> 
#> [[2]]$name
#> [1] "Alice"
#> 
#> [[2]]$age
#> [1] 30
```

### Listing the collections

The `list_collections` method returns the names of the collections
within your DB:

``` r
db$list_collections()
#> [1] "users"
```

### Counting

Using the `count` method, you can get the number of records a collection
has:

``` r
db$count(collection = "users") 
#> [1] 3
```

### Check if exists

It possible to verify if a `collection`, a `key` or a `value` exists
within your `DB`:

``` r
db$exists_collection(collection = "users")
#> [1] TRUE
```

``` r
db$exists_collection(collection = "nonexistant")
#> [1] FALSE
```

``` r
db$exists_key(collection = "users", key = "name")
#> [1] TRUE
```

``` r
db$exists_value(
  collection = "users",
  key = "name",
  value = "Alice"
)
#> [1] TRUE
```

``` r
db$exists_value(
  collection = "users",
  key = "name",
  value = "nonexistant"
)
#> [1] FALSE
```

### Clear, Drop Data

It is possible to `clear` a collection. This will remove all the
elements belonging to the collection but not drop the collection it
self:

``` r
db$insert(collection = "countries", record = list(id = 1, country = "Algeria", continent = "Africa"))

db$insert(collection = "countries", record = list(id = 1, country = "Germany", continent = "Europe"))

db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 25
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
#> 
#> 
#> 
#> $countries
#> $countries[[1]]
#> $countries[[1]]$id
#> [1] 1
#> 
#> $countries[[1]]$country
#> [1] "Algeria"
#> 
#> $countries[[1]]$continent
#> [1] "Africa"
#> 
#> 
#> $countries[[2]]
#> $countries[[2]]$id
#> [1] 1
#> 
#> $countries[[2]]$country
#> [1] "Germany"
#> 
#> $countries[[2]]$continent
#> [1] "Europe"
```

Now, look what happened when we use the `clear` method on the
`countries` collection:

``` r
db$clear("countries")

db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 25
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
#> 
#> 
#> 
#> $countries
#> list()
```

Using the `drop` method, one can drop a whole collection:

``` r
db$drop(collection = "countries")
db$get_data()
#> $users
#> $users[[1]]
#> $users[[1]]$id
#> [1] 1
#> 
#> $users[[1]]$name
#> [1] "Alice"
#> 
#> $users[[1]]$age
#> [1] 25
#> 
#> 
#> $users[[2]]
#> $users[[2]]$id
#> [1] 2
#> 
#> $users[[2]]$name
#> [1] "Bob"
#> 
#> $users[[2]]$age
#> [1] 25
#> 
#> 
#> $users[[3]]
#> $users[[3]]$id
#> [1] 3
#> 
#> $users[[3]]$name
#> [1] "Alice"
#> 
#> $users[[3]]$age
#> [1] 30
```

Finally, `drop_all` will drop all the `collections` within your `DB`:

``` r
db$drop_all()
db$get_data()
#> named list()
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
#> Error in private$.find_index_by_key(collection, key, value): Error: Collection 'nonexistant' does not exist.
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
