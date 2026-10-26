# module_build_output_and_from

Decision 989 (4): `Module.buildOutput()` holds what the loaded package's top-level `comptime` block printed, on `Ok` and on a `Refused`'s module (before its refusal); `Diagnostic.calledFrom` (the decision's `from`) holds the calls a raise at build in a helper file crossed; a `botopink.json` naming an unknown target is a `Diagnostic` of `botopink.json`.

[src/main.bp](src/main.bp)
