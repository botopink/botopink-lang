# Decision 805 — `--emit-runtime` writes the resolved tree in the compiler's own binary format, uncompressed, one file per package, a dependency's file reused by every dependant; `--emit-resolved` stays the readable `.bp`; `Module` loses `target`; a specialised copy keeps its own name, printed between backticks (561); `$` and the prefixes `__bp_` / `Bp__` are reserved; amends 786 (1), 798 (2), (4).

[refused/src/cases/reserved_name_dollar/mod.bp](refused/src/cases/reserved_name_dollar/mod.bp)
[refused/src/cases/reserved_name_bp_prefix/mod.bp](refused/src/cases/reserved_name_bp_prefix/mod.bp)
[refused/src/cases/reserved_name_type_prefix/mod.bp](refused/src/cases/reserved_name_type_prefix/mod.bp)
