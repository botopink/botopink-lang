# Decision 1006 — 1005's shape is fixed: `conformance/modules` is a workspace whose tree is the module list; a bare `botopink build` writes a package's `.bpr` and its key, no `out/`; `build` and `run --target <t>` at a workspace root run one process per member; `run --cold` reuses a fresh `.bpr`; answers 1005-a (a) on all four; amends 1005, 509 (4)–(5), 990 (6).

[cells/module_bpr_reused_across_targets/src/main.bp](cells/module_bpr_reused_across_targets/src/main.bp)
[cells/module_bpr_stale_rebuilt/src/main.bp](cells/module_bpr_stale_rebuilt/src/main.bp)
