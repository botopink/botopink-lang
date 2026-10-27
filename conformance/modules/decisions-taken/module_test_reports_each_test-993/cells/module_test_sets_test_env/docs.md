# module_test_sets_test_env

Decisions 772 and 993 (3): ``m.`test`()`` sets what `botopink test`'s runner sets — `BOTOPINK_TEST_NAME` the running test's name while its body runs, `snap`'s source for a snapshot's name, and `BOTOPINK_TEST_TMPDIR` an absolute scratch directory of the call's own, removed after it; outside the call neither is set. Three targets: `env.read` has no wasm binding, and `botopink test` sets neither there.

[src/main.bp](src/main.bp)
