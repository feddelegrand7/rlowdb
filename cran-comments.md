## R CMD check results

0 errors | 0 warnings | 1 note

* I've fixed the following comments:

------------------------
Please omit the redundant "for R" at the end of your title.

\dontrun{} should only be used if the example really cannot be executed
(e.g. because of missing additional software, missing API keys, ...) by
the user. That's why wrapping examples in \dontrun{} adds the comment
("# Not run:") as a warning for the user. Does not seem necessary.
Please replace \dontrun with \donttest.
Please unwrap the examples if they are executable in < 5 sec, or create
additionally small toy examples to allow automatic testing. (You could
also replace \dontrun{} with \donttest, if it takes longer than 5 sec to
be executed, but it would be preferable to have automatic checks for
functions. Otherwise, you can also write some tests.)
Examples within \dontrun in
rlowdb.Rd
For more details:
<https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples>


Please fix and resubmit.

Best,
Benjamin Altmann
------------------------
