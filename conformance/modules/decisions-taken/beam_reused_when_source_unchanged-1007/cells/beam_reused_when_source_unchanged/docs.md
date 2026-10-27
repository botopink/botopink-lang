# beam_reused_when_source_unchanged

The reference text this cell shows (from `conformance/docs.md`, § Backends):

> On `erlang` and `beam` a module's `.beam` in the target's folder (`out/erl/`, `out/beam/`) is loaded as it is while
> its emitted source is unchanged, the package's own modules included: beside each `.beam` a record holds the hash of
> the `.erl` / `.S` it was compiled from, the compiler's source stamp and the OTP release, and `botopink run --target
> erlang|beam` compiles only the modules whose record is missing or differs — never by a file time. The build's OTP check
> writes the own modules' `.beam` there, so a run after a build compiles nothing it already checked; a dependency's
> `.beam` still comes from the code cache. `build --cold` compiles every module again; `run --cold` reuses a `.beam`
> whose record matches (decision 1007).

Run twice on `erlang` (and on `beam`), the second run compiles no module — every `.beam` the same file — and
answers the same (`modules/compiler-cli/tests/beam_reuse.sh`).
