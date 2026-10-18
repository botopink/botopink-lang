# dependency_target_missing

The reference text this cell shows (from `conformance/docs.md`, § The manifest schema — `botopink.json`):

> A declared dependency's `targets` hold every target of the package that
> declares it (decision 676): one that lacks a target is refused at the
> dependant's manifest, on the dependency's line, whatever target the build
> is for — `error[dependency-target-missing]: kit declares no erlang, beam,
> wasm targets` —, and each dependency's own dependencies answer to its
> targets, so the whole graph builds for every target of the root.
