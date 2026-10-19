# print_local_shadows_import

The reference text this cell shows (from `conformance/docs.md`, § `print` and `panic`):

> A local binding named `print` shadows the import inside its scope and reads as the local; the
> import still binds `print` outside it, so std's `io/terminal` module is part of the build on
> every target.
