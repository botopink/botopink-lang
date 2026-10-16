# import_std_leaf_field_types

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> A type leaf brings the types its fields and methods name along, as types —
> from std as from a module of the package: `import {failure.HostError} from
> "std"` alone builds a `HostError` with `name: .Error` and matches its `name`
> by the variants of `HostErrorName`, which it never names. A refusal met in a
> std module's declaration is located in that module's file:
