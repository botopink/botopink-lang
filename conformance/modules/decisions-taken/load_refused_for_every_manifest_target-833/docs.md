# Decision 833 — A `compiler.load` file is checked for every target the caller's manifest declares — every target when it declares none —, never for the build's `--target`; its target refusals join its answer, one per host binding; amends 780 (1), 782 (1).

After the nested compile, a loaded file's own modules are checked as `botopink build` checks them on each target the caller's
manifest declares (every target when it declares none), never the build's `--target`: a std call that reaches a host
declaration with no binding for a target, and `compiler.beamMemory` off the BEAM, are refusals of the file, with the texts,
codes and places `botopink build` prints on that target. The refusals follow the analysis ones, in the order `node`,
`erlang`, the manifest's wasm host. `load` answers the same on every target, so the resolved tree stays one; a loaded
package's `run()` is still refused at `emit` for the target built.

[cells/load_refused_for_every_manifest_target/src/main.bp](cells/load_refused_for_every_manifest_target/src/main.bp)
