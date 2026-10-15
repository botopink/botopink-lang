# defer_reads_var_set_in_arm

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A reassignment inside a nested arm counts, a value `case`'s included: an arm that reassigns a `var` and
> then panics hands the `defer` the new value:
