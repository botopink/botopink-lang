# root_module_unimported_type_error

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> The root package is a package like any other (decision 677): every module
> under its `src/` is in the program, imported or not, and its executors run
> in the order above, after every dependency's. A module no `mod` names and
> no module imports
> is checked, compiled and linked, so a type error in it refuses the build.
