# Decision 1050 — import aliases do not exist: an import from `"@/lib.db"` is an unresolved import source, as `check` and `build` answer, and `compiler.load` answers the same `Diagnostic`.

`import {readPost} from "@/lib.db"` names no package: `from` names std, a bundled package or a dependency
declared in `botopink.json`, and there is no alias key (decision 1048 refuses it as an unknown manifest key,
proven by `modules/compiler-cli/tests/import_alias_refused.sh`). A program that loads such a package through
`compiler.load` sees the refusal as `check` prints it, a `Diagnostic` of the unresolved import source
(decisions 242, 989 (4)), alike on all four targets, not an `unbound variable` of the use.

[cases/alias_import_unresolved/src/main.bp](cases/alias_import_unresolved/src/main.bp)
