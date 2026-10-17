# array_push_rebinds_var

The reference text this cell shows (from `conformance/docs.md`, § Arrays):

> An array method **answers a value and leaves its receiver alone**, on every
> target. A statement `v.push(x)` on a `var` rebinds the `var` to the grown
> array: a `val` that read the array before keeps the array of its moment.
