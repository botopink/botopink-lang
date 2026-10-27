# module_bpr_stale_rebuilt

The reference text this cell shows (from `conformance/docs.md`, § Backends):

> A bare `botopink build` — no `--target` — runs the analysis and comptime and writes the package's `.bpr` set
> (the resolved tree of every package of the program, decision 805) and its key to
> `<cache root>/.botopinkbuild/runtime/<package>/`, and no `out/`; `--emit-runtime <dir>` names another directory.
> `botopink build --target <t>` and `botopink run --target <t>` (or `run` with the manifest's `target`) emit from that
> set while it is fresh, with no comptime — nothing of the build phase is printed —, and otherwise build it, write it
> and emit in one comptime pass. The key is a hash of the compiler's source stamp (never the host it was built on), every
> file of the package but `.botopinkbuild/`, `out/`, hidden entries and `node_modules`, its effective manifest and each
> dependency's key; no file time is read. `build --cold` ignores the key and rebuilds; `run --cold` reuses a fresh set
> and reads no code cache (decision 1006).

A changed byte of `src/greeting.bp` changes the key: the next run builds the set again — `comptime ran` printed
once more — and answers the changed program; the run after it reuses that set
(`modules/compiler-cli/tests/runtime_reuse.sh`).
