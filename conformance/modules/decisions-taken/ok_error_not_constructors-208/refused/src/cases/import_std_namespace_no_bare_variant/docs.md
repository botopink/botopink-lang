# import_std_namespace_no_bare_variant

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> A namespace brings no bare name of its module, std's as a module of the
> package: neither a type's constructor nor an enum's variant enters scope. After
> `import {failure} from "std"`, `failure`'s `HostErrorName.Error` is
> `failure.HostErrorName.Error`, and a bare `Error` is what it is without the
> import — no name in an expression (decision 208), the `Result`'s error in a
> pattern:
