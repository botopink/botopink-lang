# embed_path_not_known

The reference text this cell shows (from `conformance/docs.md`, § `Asset`):

> An absolute path is `error[embed-path-absolute]` and a path with a `..` segment
> `error[embed-path-outside-package]`, at the argument; a path that names no file
> of the package is `error[embed-file-missing]`, at the call; a path not known at
> build — a parameter, a local — is `error[comptime-arg-not-known]`, at the
> argument.
