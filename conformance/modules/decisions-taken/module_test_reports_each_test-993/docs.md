# Decision 993 — The gate's library check runs in-process, as 989's suite does: a botopink program loads every library and every workspace member with `compiler.load`, runs its tests through `Module.test()` and reports per package and target — no spawned `botopink test`, no `botopink-lib-test`; amends 780 (1), 982 (1), 989, 513 for a loaded package.

[cells/load_library_entry_root/src/main.bp](cells/load_library_entry_root/src/main.bp)
[cells/load_resolves_own_dependencies/src/main.bp](cells/load_resolves_own_dependencies/src/main.bp)
