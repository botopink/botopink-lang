# library_check_one_process_per_package

The program `conformance/run.sh` writes for each package of `botopink packages --list` and runs on each target as
a process of its own (decision 1004 (1)): it loads the package by name (`compiler.load(package: …)`, decision 993
(2)) and runs its tests in process (``m.`test`()``, 993 (3)), one line per test and a summary. Here it loads
`good`, beside the cell in `repository/`, and answers its two tests.

The other packages there are the runner's own self-test (`conformance/run.sh --self-test`): `hard` has no entry, so
its program does not build; `hangs` has a test that never ends, stopped at the run's bound; `broken`'s manifest
is refused, `not-a-package` in the list, never loaded. Each is red alone, on each target, while `good` answers, and the
run's count is the list's: one verdict per package per target.
