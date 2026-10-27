# Decision 993 — The gate's library check runs in-process, as 989's suite does: a botopink program loads every library and every workspace member with `compiler.load`, runs its tests through `Module.test()` and reports per package and target — no spawned `botopink test`, no `botopink-lib-test`; amends 780 (1), 982 (1), 989, 513 for a loaded package.

[cells/load_library_entry_root/src/main.bp](cells/load_library_entry_root/src/main.bp)
[cells/load_resolves_own_dependencies/src/main.bp](cells/load_resolves_own_dependencies/src/main.bp)
[cells/load_by_package_name/src/main.bp](cells/load_by_package_name/src/main.bp)
[cases/load_by_package_name_unknown/src/main.bp](cases/load_by_package_name_unknown/src/main.bp)

``m.`test`()`` runs the loaded package's tests in-process: one `TestCase` per test with what it printed, a failing or
aborting test a case with `ok: false` and the next one run, a crash outside every test `.Abort`, an `Async` when a
test awaits (`module_test_reports_each_test`); a package the target refuses answers `.Refused`
(`module_test_refused_on_target`), one whose manifest leaves the target out `.Excluded`
(`module_test_excluded_target`), none of its tests run; four targets.

[cells/module_test_reports_each_test/src/main.bp](cells/module_test_reports_each_test/src/main.bp)
[cells/module_test_refused_on_target/src/main.bp](cells/module_test_refused_on_target/src/main.bp)
[cells/module_test_excluded_target/src/main.bp](cells/module_test_excluded_target/src/main.bp)
