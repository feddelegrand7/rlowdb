── R CMD check results ─────────────── rlowdb 0.2.0 ────
Duration: 8s

❯ checking for future file timestamps ... NOTE
  unable to verify current time

0 errors ✔ | 0 warnings ✔ | 1 note ✖

# rlowdb 0.2.0

* Adding the `verbose` parameter which when set to `TRUE` will print informative information to the console.

* Adding the `auto_commit` parameter which when set to `FALSE`, the user will have to use the `commit` method in order to reflect the data changes into the `JSON` file.

* Adding new methods:
- `count_values`
- `list_keys`
- `rename_collection`
- `set_auto_commit`
- `set_verbose`
- `status`
