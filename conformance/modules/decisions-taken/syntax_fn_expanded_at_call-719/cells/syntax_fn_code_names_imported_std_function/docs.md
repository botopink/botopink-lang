# syntax_fn_code_names_imported_std_function

The code a `syntax` expression function writes resolves each name in the scope of whoever wrote it (decisions 170,
578, 719, 841): `logger` imports `print`, writes `print(…)` in its `code` tree, and the call site in `main` imports
nothing — for a `-> void` answer and for `-> anyvalue`. The tree prints its label and the expression as written.
