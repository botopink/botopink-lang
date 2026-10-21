# Decision 676 — Every declared dependency's `"targets"` holds every target of the package that declares it, checked at the manifest; 660's order is depth-first by the manifests and by the deepest chain, as built.

The example is a program that uses `kit-link`, a declared dependency. Its package builds for commonJS and erlang, and `kit-link`'s manifest names commonJS alone, so the build is refused at `kit-link`'s line of the dependant's `botopink.json`, `dependency-target-missing`, naming the package and the missing erlang target, whichever target is being built. The same check runs down the graph, each dependency's dependencies against its own targets. A draft carries no manifest and no dependency, so the refusal waits for the promoted cell's `botopink.json` and its `kit-link` package.

Cells in this repository that also bear on it: `modules/manifest/cells/manifest_targets_host_binding`.


[cells/init_order_packages/src/main.bp](cells/init_order_packages/src/main.bp)
[cells/dependency_target_missing/src/main.bp](cells/dependency_target_missing/src/main.bp)
[cells/dependency_target_missing_transitive/src/main.bp](cells/dependency_target_missing_transitive/src/main.bp)
[cells/init_order_depth_not_count/src/main.bp](cells/init_order_depth_not_count/src/main.bp)
[cells/narrowing_on_dependency_target_missing/src/main.bp](cells/narrowing_on_dependency_target_missing/src/main.bp)
