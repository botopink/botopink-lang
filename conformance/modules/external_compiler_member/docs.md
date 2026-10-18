# external_compiler_member

The reference text this cell shows (from `conformance/docs.md`, § `compiler`):

> What the compiler does is a member of `compiler` (decision 606 (3)): `compiler.typeInfo(T)`
> answers `Info<T>` (decision 630), `#[compiler.external(…)]` names a `declare fn`'s host
> sources. In a body that runs when the program runs, `compiler` is written
> under `comptime` — `val name = comptime compiler.typeInfo(City).name;` — and the answer is
> computed at build.
