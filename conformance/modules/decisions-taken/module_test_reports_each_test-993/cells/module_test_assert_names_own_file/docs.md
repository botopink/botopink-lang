# module_test_assert_names_own_file

Decision 993 (3): ``m.`test`()`` runs the loaded package's tests as `botopink test` does, so a failing `assert` names the file it is written in — the package's root, one of its `mod`s, a `test/` suite file — with its line and column, on every target (527 (2)).

[src/main.bp](src/main.bp)
