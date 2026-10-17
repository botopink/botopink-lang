# block_void_value_refused

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A block handed where a function is expected is refused at the block, with the hint "expected a
> function, got a block's value — missing `->`?"; a trailing lambda follows the same rule, so one
> with no parameter is written `f(x) { -> … }`. A block whose value is `void` handed where
> `unknown` is expected is refused. `@block` is removed, refused at the builtin, its fix the block
> `{ … }`:
